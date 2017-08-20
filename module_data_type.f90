!------------------------------------------------------------------------
!  Module	    :            module_data_type
!------------------------------------------------------------------------
!  Purpose      :
!
!  Details      ：
!
!  Input        :
!
!  Input/output :
!
!  Output       :
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
!  Ruizhi Yang, 2017 Aug
!------------------------------------------------------------------------

MODULE module_data_type

    !--------------------------------------------------------------------
    !  MODULE
    !--------------------------------------------------------------------
    USE module_constants

IMPLICIT NONE

    TYPE dof
    !------------------------ TYPE dof ------------------------
    ! the total number dof of the system is number of joint*6, because each joint
    ! has 6 degree of freedoms
    ! Provide a type to describe property of each degree of freedom
    !                 {dof_id,dof_type,stiffness,damping}
    !                or
    !                 {dof_id,dof_type,motion_type,motion_params}
    !                depending on whether dof_type is 'passive' or 'active'.
    !                     dof_id:    ID of the degree of freedom. 1--6
    !                The other entries for a 'passive' degree of freedom are
    !                     stiff: Stiffness of a spring associated with the
    !                                degree of freedom.
    !                     damp:   Damping coefficient of a spring associated
    !                                with the degree of freedom.
    !                 or for an 'active' degree of freedom
    !                     motion_type: Can be 'ramp','oscillatory',
    !                                        'velocity','hold'
    !                     motion_params: An array of parameters specifying the
    !                                    behavior of the specified motion.
    !                                    1. For 'ramp', this comes as a list
    !                                     [a,amp1,t_hold1,rate1,amp2,t_hold2,...]
    !                                    where a is the smoothing value,
    !                                    each pair ampj,t_holdj specifies
    !                                    to hold for at a certain value ampj
    !                                    for duration t_holdj, and each of
    !                                    these hold pairs is joined by a rate
    !                                    that specifies the duration of the ramp.
    !                                    2. For 'oscillatory',the list is
    !                                     [amp,freq,phase]
    !                                    3. For 'velocity',the list is
    !                                      [velocity]
    !                                    which specifies the constant velocity
    !                                    at which to move that degree.
    !                                    4. For 'hold', the list is a single value
    !                                     [amp]
    !                                    at which to hold the degree of freedom.
    !                  If no sub-array is given for a degree of freedom, then
    !                  the default is 'passive' with no stiffness/damping,
    !                  except for cases in which body1=0, in which case
    !                  default is 'active' with a hold at zero.
        INTEGER                             :: dof_id
        CHARACTER(LEN = max_char)           :: dof_type
        REAL(dp)                            :: stiff,damp
        CHARACTER(LEN = max_char)           :: motion_type
        REAL(dp),ALLOCATABLE                :: motion_params(:)
    END TYPE


    TYPE config_body
    !------------------------ TYPE config_body ------------------------
    ! This type is designed for gather input data for body from config files.
    ! Variable dimension is for a single body
    !
    !   'verts' -- matrix of vertex coordinates, with line No. equal to
    !             the number of vertices in the polygon. The coordinates are
    !             given in the coordinate system of the body. For a polygon, it
    !             is assumed that the polygon lies in the z-x plane of this
    !             coordinate system, so the vertices need only contain pairs of
    !             coordinates [z,x]. For example, [0 0;1 0;1 1;0 1] for
    !             a square.
    !   'nverts' -- number of verts of a single body
    !   'rhob'  -- Value of the mass per unit volume (or mass per unit area
    !           for a polygon of zero thickness). (Default is 1.)
        INTEGER                                     :: nbody
        INTEGER                                     :: nverts
        REAL(dp),DIMENSION(:,:),ALLOCATABLE         :: verts
        REAL(dp)                                    :: rhob
    END TYPE


    TYPE config_joint
    !------------------------ TYPE config_joint ------------------------
    ! This type is designed for gather input data for joint from config files.
    ! Variable dimension is for a single joint.
    !
    !  joint_type -- 'revolute', 'cylindrical', 'spherical', 'prismatic', 'free'
    !  joint_id -- joint_id should be the same with the body_id it connects to.
    !  q_init -- Initial angle/position of a joint in its parent body's body
    !            coordinate  [theta_x,theta_y,theta_z,x,y,z]. Also can be
    !            interpreted as the relative angle/position in the unconstrained
    !            dof. Only components of the unconstrained dof can be non-zero.
    !            This corresponds to Xj. (theta of Euler angles in radian)
    !            If q_init is used on the first joint, then it's the orientation
    !            of this first joint to inertial system.
    !  shape1 -- Consists of [angles1 loc1] of the Matlab code. This is fixed
    !            information once the shape of body is fixed. It describes the
    !            location of the joint in the parent body coordinate. Also can be
    !            interpreted as the relative angle/position in the constrained
    !            dof. Only components of the constrained dof can be non-zero.
    !            If shape1 is used on the first joint, then it's the orientation
    !            of this first joint to inertial system.
    !  shape2 -- Similar to shape1, but describes the location of the joint in
    !            the child body coordinate. Normally, shape2 is 0 if there's no
    !            distance gap or angle gap between two adjacent bodies.
    !  body1,body2 -- the parent body id and the child body id connecting the joint
        CHARACTER(LEN = max_char)                   :: joint_type
        INTEGER                                     :: joint_id
        REAL(dp),DIMENSION(6)                       :: q_init
        REAL(dp),DIMENSION(6)                       :: shape1,shape2
        INTEGER                                     :: body1,body2
        TYPE(dof),DIMENSION(6)                      :: joint_dof
    END TYPE


    TYPE single_body
    !------------------------ TYPE single_body ------------------------
    ! This is the data type of one body. Only verts_i need to be updated.
    ! Information in the body structure does not depend on time,
    ! it's only local info of a single body in the body coordinate
    !    body_id: id number of this body
    !    parent_id: id number of this body's parent. A body can only
    !               have one parent
    !    child_id: id number of this body's child. A body can have
    !               more than one child
    !    (deleted)shape: shape of the body, only 'polygon'
    !    nchild: number of child
    !    nverts: number of verts
    !    verts: body verts coordinate in body coordinate, expressed
    !           in [x y z]. Different line is different vert.
    !    verts_i: verts coordinate in the inertia frame
    !    x_c: body center in the body coordinate, with [x y z]
    !    mass: mass of the body
    !    inertia_c: body inertia at center
    !    Xj_to_c: transform matrix from the joint(same id with this body)
    !             to body center
    !    support: body hierarchy number before this body
        INTEGER                                 :: body_id,parent_id
        INTEGER,DIMENSION(:),ALLOCATABLE        :: child_id
        INTEGER                                 :: nchild,nverts
        REAL(dp),DIMENSION(:,:),ALLOCATABLE     :: verts,verts_i
        REAL(dp),DIMENSION(3)                   :: x_c
        REAL(dp)                                :: mass
        REAL(dp),DIMENSION(6,6)                 :: inertia_c,Xj_to_c
        REAL(dp),DIMENSION(:),ALLOCATABLE       :: support
    END TYPE


    TYPE single_joint
    !------------------------ TYPE single_joint ------------------------
    !
    !


    END TYPE


    !--------------------------------------------------------------------
    !  MODULE variables
    !--------------------------------------------------------------------

    ! Assume that all the bodies are the same
    TYPE(config_body)                           :: input_body

    ! Not all the joints are the same
    TYPE(config_joint),ALLOCATABLE              :: input_joint(:)

    ! body_system consists of n number of TYPE single_body
    TYPE(single_body),ALLOCATABLE               :: body_system(:)

    ! joint_system consists of n number of TYPE single_joint
    TYPE(single_joint),ALLOCATABLE              :: joint_system(:)




END MODULE module_data_type