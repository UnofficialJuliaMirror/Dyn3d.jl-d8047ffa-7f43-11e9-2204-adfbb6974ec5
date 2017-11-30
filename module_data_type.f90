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
        REAL(dp),DIMENSION(:),ALLOCATABLE           :: q_init
        REAL(dp),DIMENSION(6)                       :: shape1,shape2
        INTEGER                                     :: body1
        TYPE(dof),DIMENSION(:),ALLOCATABLE          :: joint_dof
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
    !    x_0: origin of this body in inertial frame
    !    mass: mass of the body
    !    inertia_c: body inertia at center
    !    Xj_to_c: transform matrix from the joint(same id with this body)
    !             to body center
    !    inertia_b -- body inertia at it's origin, i.e. at the joint it connects
    !              to. This inertia is described in local body coord.
    !    Xb_to_i -- transform from body(at its first point) to inertia system
    !    Xp_to_b -- transform from the parent body to the current body
    !    1 -- body position expressed in [theta_x,theta_y,theta_z,x,y,z]
    !    v -- body velocity expressed in [wx,wy,wz,ux,uy,uz]
    !    c -- body acceleration of the local single body
        INTEGER                                 :: body_id,parent_id
        INTEGER,DIMENSION(:),ALLOCATABLE        :: child_id
        INTEGER                                 :: nchild,nverts
        REAL(dp),DIMENSION(:,:),ALLOCATABLE     :: verts,verts_i
        REAL(dp),DIMENSION(3)                   :: x_c,x_0
        REAL(dp)                                :: mass
        REAL(dp),DIMENSION(6,6)                 :: Xj_to_c
        REAL(dp),DIMENSION(6,6)                 :: inertia_c,inertia_b
        REAL(dp),DIMENSION(6,6)                 :: Xb_to_i
        REAL(dp),DIMENSION(6,6)                 :: Xp_to_b
        REAL(dp),DIMENSION(6,1)                 :: q,v,c
    END TYPE


    TYPE single_joint
    !------------------------ TYPE single_joint ------------------------
    ! joint_type -- 'revolute','free' etc.
    ! joint_id -- index of this joint
    ! body1 -- the index of the parent body of this joint
    ! shape1 -- the coord of this joint described in the local body coord
    !           of the parent body of this joint
    ! shape2 -- the coord of this joint described in the local body coord
    !           of the child body of this joint
    ! nudof -- For a single joint, the total number of unconstrained dof
    ! np -- For a single joint, the total number of unconstrained passive dof
    ! na -- For a single joint, the total number of unconstrained active dof
    ! udof -- In the 6d expression, the unconstrained dof index. For example,
    !         free joint: [1 2 3 4 5 6]
    !         revolute joint: 3
    !         planar joint: [3 4 5]
    !         cylindrical joint: [3 6]
    !         spherical joint: [1 2 3]
    !         prismatic joint: 6
    ! cdof -- the constrained part other than udof
    ! udof_p -- the passive ones in the udof
    ! udof_a --  the ones in udof with active prescribed motion
    ! i_udof_p -- the index of udof_p in udof. For example, if we have a
    !                 free joint with udof=[1 2 3 4 5 6] and udof_p=3, then
    !                 index_udof_p = 3, index_udof_a = [1 2 4 5 6]
    ! cdof_HERK_a -- the index of active dof in the cdof_HERK array
    ! udofmap -- list all the udof of all joints in an "total array", udofmap
    !            refers to the index of the current dof in the "total array"
    ! S -- the dof basis matrix for every body, depending on joint type only
    !      , expressed in 6 lines and nudof columns
    ! T -- the other part of S
    ! joint_dof -- described in details in add_joint
    ! qJ -- position vector of this joint in the parent body's body coord
    ! vJ -- joint velocity in the parent body's body coord, which is S*qdot
    ! cJ -- acceleration vector of this joint in the parent body's body coord
    ! Note that qJ,vJ and cJ are stored in full 6-dimension. Those constrained
    ! dofs are given value 0.
    ! Xj -- 6d transformation matrix, consider joint rotation only
    ! Xp_to_j -- transform matrix, considering parent body to the joint
    ! xj_to_ch -- transform matrix, considering joint to the child body
        CHARACTER(LEN = max_char)               :: joint_type
        INTEGER                                 :: joint_id
        INTEGER                                 :: body1
        REAL(dp),DIMENSION(6)                   :: shape1,shape2
        INTEGER                                 :: nudof,ncdof
        INTEGER                                 :: nudof_HERK,ncdof_HERK
        INTEGER                                 :: np,na
        INTEGER,DIMENSION(:),ALLOCATABLE        :: udof,cdof
        INTEGER,DIMENSION(:),ALLOCATABLE        :: udof_HERK,cdof_HERK
        INTEGER,DIMENSION(:),ALLOCATABLE        :: udof_p,udof_a
        INTEGER,DIMENSION(:),ALLOCATABLE        :: i_udof_p
        INTEGER,DIMENSION(:),ALLOCATABLE        :: cdof_HERK_a
        INTEGER,DIMENSION(:),ALLOCATABLE        :: udofmap
        INTEGER,DIMENSION(:),ALLOCATABLE        :: cdof_HERK_map
        INTEGER,DIMENSION(:,:),ALLOCATABLE      :: S,T
        INTEGER,DIMENSION(:,:),ALLOCATABLE      :: T_HERK
        TYPE(dof),DIMENSION(:),ALLOCATABLE      :: joint_dof
        REAL(dp),DIMENSION(6,1)                 :: qJ,vJ,cJ
        REAL(dp),DIMENSION(6,6)                 :: Xj,Xp_to_j,Xj_to_ch

    END TYPE


    TYPE system_params
    ! to be used in the overall_system structure
    ! defines a small structure to store some physical and numerical
    ! constants.
        REAL(dp),DIMENSION(3)                   :: gravity
        REAL(dp)                                :: dt,tf,tol
        INTEGER                                 :: nstep,scheme
    END TYPE

    TYPE system_solution
    ! to be used in the overall_system structure
    ! defines a structure storing solution. The dimension of t depends on
    ! nstep, and the dimension of y depends on system.nbody. Should have
    ! t(nstep),y(nstep,2*6*system%nbody).
    ! y = [q,v] for all bodies in the system
        REAL(dp),DIMENSION(:),ALLOCATABLE       :: t
        REAL(dp),DIMENSION(:,:),ALLOCATABLE     :: y
    END TYPE


    TYPE overall_system
    ! This is the structure of the overall system
    ! njoint -- number of joint, equals to number of body
    ! params -- look at TYPE system_params
    ! time -- the time array that the ODE system is solved at
    ! soln -- look at TYPE system_solution
    ! ndof -- total number of dofs of the system, which is 6*system%nbody
    ! nudof -- total number of unconstrained dofs of the system
    ! ncdof -- total number of constrained dofs of the system
    ! np -- total number of passive unconstrained dofs of the system
    ! na -- total number of active unconstrained dofs of the system
    ! the rest parameters have similar definitions with those in the
    ! joint_system structure. The difference is that variables here
    ! take the index considering the whole system, lining up all joints
    ! kinmap -- This is a matrix of dimension system%na by 2.
    !           It stores the info like this [1 1]
    !                                        [1 2]
    !                                        [1 3]
    !                                        [1 4]
    !                                        [1 5]
    !                                        [1 6]
    !                                        [2 1]
    !                                        [3 1]
    !                                        [4 1]
    !            in order to keep the mapping information between
    !            each joint and the system. This is used to assign
    !            active motion data to kindata. Only active dofs here
    ! kindata -- This is the data base of prescribed active motion.
    !            This matrix have the dimension of nstep lines and
    !            1+3*system%na columns. The first column is time,
    !            then every continuous 3 columns are position, velocity
    !            and acceleration of each active udof.
    ! P_map -- This matrix maps the hierarchy relation from joint to body.
    !          It consists of many [1], [-1] and [0] blocks.
        INTEGER                                 :: njoint,nbody
        TYPE(system_params)                     :: params
        REAL(dp),DIMENSION(:),ALLOCATABLE       :: time
        TYPE(system_solution)                   :: soln
        INTEGER                                 :: ndof
        INTEGER                                 :: nudof,ncdof,np,na
        INTEGER                                 :: nudof_HERK,ncdof_HERK
        INTEGER,DIMENSION(:),ALLOCATABLE        :: udof,cdof
        INTEGER,DIMENSION(:),ALLOCATABLE        :: udof_HERK,cdof_HERK
        INTEGER,DIMENSION(:),ALLOCATABLE        :: cdof_HERK_a
        INTEGER,DIMENSION(:),ALLOCATABLE        :: udof_p,udof_a
        INTEGER,DIMENSION(:),ALLOCATABLE        :: i_udof_p
        INTEGER,DIMENSION(:,:),ALLOCATABLE      :: kinmap
        REAL(dp),DIMENSION(:,:),ALLOCATABLE     :: kindata
        INTEGER,DIMENSION(:,:),ALLOCATABLE      :: P_map
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

    ! the overall system
    TYPE(overall_system)                        :: system

END MODULE module_data_type