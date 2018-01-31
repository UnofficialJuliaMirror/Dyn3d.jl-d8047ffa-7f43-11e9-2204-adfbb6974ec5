!------------------------------------------------------------------------
!  Subroutine     :          embed_system
!------------------------------------------------------------------------
!  Purpose      : This subroutine takes in q_total and qdot_total to
!                 update several things.
!                 1. update the body chain in the inertial system, including
!                    Xb_to_i, verts_i and x_0 in body_system.
!                 2. Xj, vJ and cJ got updated by calling subroutine jcalc
!                 3. updates q and qdot of the passive dofs for the
!                    joint_system structure to keep it updated.(may not be
!                    useful)
!                 4. update Xp_to_b for every body, which is the transform
!                    between parent body and the current body, i.e.
!                    Xp_to_b = Xj_to_ch*Xj*Xp_to_j

!
!  Details      ：
!
!  Input        : The total q vector, which contains all unconstrained dof
!                 , including both active ones from prescribed motion and
!                 passive ones solved from the last timestep.
!  Input/output :
!
!  Output       : No explicit output. Module data got updated
!
!  Remarks      :
!
!  References   :
!
!  Revisions    :
!------------------------------------------------------------------------
!  whirl vortex-based immersed boundary library
!  SOFIA Laboratory
!  University of California, Los Angeles
!  Los Angeles, California 90095  USA
!  Ruizhi Yang, 2017 Sep
!------------------------------------------------------------------------

SUBROUTINE embed_system

    !--------------------------------------------------------------------
    !  MODULE
    !--------------------------------------------------------------------
    USE module_constants
    USE module_data_type
    USE module_add_body_and_joint
    USE module_basic_matrix_operations

IMPLICIT NONE

    !--------------------------------------------------------------------
    !  Local variables
    !--------------------------------------------------------------------
    REAL(dp),DIMENSION(6,1)                         :: q_temp,q_temp2,q_ref
    REAL(dp),DIMENSION(6,6)                         :: Xi_to_body1,Xj_to_p
    REAL(dp),DIMENSION(6,6)                         :: Xb_to_ch,Xch_to_b
    INTEGER                                         :: i,j,child_id,pb_id
    REAL(dp),DIMENSION(3)                           :: x_temp

    !--------------------------------------------------------------------
    !  First body
    !--------------------------------------------------------------------
    ! starting from joint = 1, which is connected to the inertial system
    ! (always true) and is the parent of every other body.

    q_ref(:,1) = 0.0_dp

    ! call jcalc to update Xj and possibly qdot
    joint_system(1)%qJ = body_system(1)%q
    CALL jcalc(joint_system(1)%joint_id)

    ! calculate Xi_to_body1 for body 1
    Xi_to_body1 = MATMUL(joint_system(1)%Xj_to_ch, &
                         MATMUL(joint_system(1)%Xj,joint_system(1)%Xp_to_j))

    ! doing matrix inverse
    CALL inverse(Xi_to_body1,body_system(1)%Xb_to_i)

    ! set the origin of the reference body in inertial space
    q_temp(1:3,1) = 0.0_dp
    q_temp(4:6,1) = q_ref(4:6,1)
    q_temp = MATMUL(body_system(1)%Xb_to_i,q_temp)
    body_system(1)%x_0 = joint_system(1)%shape1(4:6) + q_temp(4:6,1)

    !--------------------------------------------------------------------
    !  First to last body following parent-child hierarchy
    !--------------------------------------------------------------------
    ! loop through all joints, calculate verts_i of its own, and properties
    ! of its child body(can be multiple)
    DO i = 1, system%njoint

        ! update verts_i
        DO j = 1, body_system(i)%nverts
            q_temp(1:3,1) = 0.0_dp
            q_temp(4:6,1) = body_system(i)%verts(j,:)
            q_temp = MATMUL(body_system(i)%Xb_to_i,q_temp)
            body_system(i)%verts_i(j,:) = q_temp(4:6,1) + body_system(i)%x_0
        END DO

        ! for this joint, loop through every child of it. DO loop will not
        ! execute when nchild=0
        IF(body_system(i)%nchild /= 0) THEN

        DO j = 1,body_system(i)%nchild
            child_id = body_system(i)%child_id(j)

            ! call jcalc to update Xj and possibly vJ
            joint_system(child_id)%qJ = body_system(child_id)%q - &
                            MATMUL(body_system(child_id)%Xp_to_b, body_system(i)%q)
            CALL jcalc(joint_system(child_id)%joint_id)

            ! calculate a local variable Xb_to_ch for calculating Xb_to_i of
            ! the child body
            Xb_to_ch = MATMUL(joint_system(child_id)%Xj_to_ch, &
                              MATMUL(joint_system(child_id)%Xj, &
                                     joint_system(child_id)%Xp_to_j))

            ! update Xb_to_i for this child
            CALL inverse(Xb_to_ch, Xch_to_b)
            body_system(child_id)%Xb_to_i = MATMUL(body_system(i)%Xb_to_i, Xch_to_b)

            ! update x_0 for this child in the inertial system
            ! step 1: find the vector to account for shape1(shape1 is expressed
            !         in the parent joint coord)
            q_temp(1:3,1) = 0.0_dp
            q_temp(4:6,1) = joint_system(child_id)%shape1(4:6)
            q_temp = MATMUL(body_system(i)%Xb_to_i,q_temp)
            x_temp = q_temp(4:6,1) + body_system(i)%x_0

            ! step 2: find the vector to account for joint rotation(Xj is expressed
            ! in the child joint coord)
            q_temp2 = joint_system(child_id)%qJ
            q_temp(1:3,1) = 0.0_dp
            q_temp(4:6,1) = q_temp2(4:6,1)
            CALL inverse(joint_system(child_id)%Xp_to_j,Xj_to_p)
            q_temp = MATMUL(body_system(i)%Xb_to_i, &
                            MATMUL(Xj_to_p,q_temp))
            x_temp = x_temp + q_temp(4:6,1)

            ! step 3: find the vector to accout for shape2(shape2 is expressed
            !         in the child joint coord)
            q_temp(1:3,1) = 0.0_dp
            q_temp(4:6,1) = -joint_system(child_id)%shape2(4:6)
            q_temp = MATMUL(body_system(child_id)%Xb_to_i,q_temp)
            x_temp = x_temp + q_temp(4:6,1)

            ! assign to x_0
            body_system(child_id)%x_0 = x_temp
        END DO
        END IF
    END DO

    !--------------------------------------------------------------------
    !  Update body_system(i)%Xp_to_b
    !--------------------------------------------------------------------
    ! from body n to body 1
    DO i = system%nbody, 1 ,-1
        ! the body_id of this body's parent body
        pb_id = body_system(i)%parent_id

        body_system(i)%Xp_to_b = MATMUL(joint_system(i)%Xj_to_ch, &
                                        MATMUL(joint_system(i)%Xj, &
                                               joint_system(i)%Xp_to_j))
    END DO

END SUBROUTINE