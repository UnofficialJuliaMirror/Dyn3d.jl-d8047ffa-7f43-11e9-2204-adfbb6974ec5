!------------------------------------------------------------------------
!  Program     :            dyn3d
!------------------------------------------------------------------------
!  Purpose      : The main routine
!
!  Details      ：
!
!  Input        :
!
!  Input/output :
!
!  Output       :
!
!  Remarks      : This program is written based on the Matlab version by
!                 Prof. Eldredge
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
PROGRAM dyn3d

    !--------------------------------------------------------------------
    !  MODULE
    !--------------------------------------------------------------------
    USE module_constants
    USE module_data_type
    USE module_init_system
    USE module_write_structure

IMPLICIT NONE

    ! add_body, add_joint and assemble them
    CALL config_3d_hinged

    ! initialize system
    CALL init_system

    ! write data
    CALL write_structure

END PROGRAM dyn3d