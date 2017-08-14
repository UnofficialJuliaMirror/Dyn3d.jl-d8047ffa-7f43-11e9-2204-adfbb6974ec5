!------------------------------------------------------------------------
!  Subroutine	    :            ones
!------------------------------------------------------------------------
!  Purpose      : given matrix dimension, return a 2d identity matrix
!
!  Details      ： allow operator overloading for future use
!
!  Input        : matrix dimension n
!
!  Input/output :
!
!  Output       : identity matrix E
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
!------------------------------------------------------------------------

SUBROUTINE ones_s(n,E)

IMPLICIT NONE

    INTEGER                    :: n,i,j
    REAL,DIMENSION(n,n)        :: E

    DO i = 1, n
        DO j = 1, n
            E(i,j) = 0
        END DO
        E(i,i) = 1
    END DO

END SUBROUTINE ones_s