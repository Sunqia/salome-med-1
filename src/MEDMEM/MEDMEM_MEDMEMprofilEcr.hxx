// Copyright (C) 2005  OPEN CASCADE, CEA, EDF R&D, LEG
//           PRINCIPIA R&D, EADS CCR, Lip6, BV, CEDRAT
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either 
// version 2.1 of the License.
// 
// This library is distributed in the hope that it will be useful 
// but WITHOUT ANY WARRANTY; without even the implied warranty of 
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU 
// Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public  
// License along with this library; if not, write to the Free Software 
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
// 
// See http://www.salome-platform.org/ or email : webmaster.salome@opencascade.com
// 
#ifndef  MEDMEM_MEDMEM_PROFILECR_HXX
#define  MEDMEM_MEDMEM_PROFILECR_HXX
/*
 * En attendant une correction de la gestion du mode d'acc�s au fichier dans MEDfichier
 * on int�gre la correction ici.
 */
namespace med_2_2 {
  extern "C" {

# define __UTILITES_H__
#include <med_outils.h>
# undef __UTILITES_H__

#include <string.h>
#include <stdlib.h>

    med_err
    MEDMEMprofilEcr(med_idt fid,med_int *pflval,med_int n,char *profilname);

  }
}

#endif