//=============================================================================
// File      : MEDMEM_Group_i.cxx
// Project   : SALOME
// Author    : EDF 
// Copyright : EDF 2002
// $Header: /export/home/PAL/MED_SRC/src/MEDMEM_I/MEDMEM_Group_i.cxx
//=============================================================================

#include <vector>

#include "utilities.h"
#include "Utils_CorbaException.hxx"

#include "MEDMEM_Group_i.hxx"
#include "MEDMEM_Family_i.hxx"

#include "MEDMEM_Group.hxx"
#include "MEDMEM_Family.hxx"
using namespace MEDMEM;

//=============================================================================
/*!
 * Default constructor
 */
//=============================================================================
GROUP_i::GROUP_i():_group((::GROUP*)NULL),
		   SUPPORT_i()
{
	BEGIN_OF("Default Constructor GROUP_i");
        END_OF("Default Constructor GROUP_i");
};
//=============================================================================
/*!
 * Destructor
 */
//=============================================================================
GROUP_i::~GROUP_i()
{
};
//=============================================================================
/*!
 * Constructor
 */
//=============================================================================
GROUP_i::GROUP_i(const ::GROUP * const g):_group(g),
		   SUPPORT_i(g)
{
	BEGIN_OF("Constructor GROUP_i");
        END_OF("Constructor GROUP_i");
};
//=============================================================================
/*!
 * Constructor par recopie
 */
//=============================================================================
GROUP_i::GROUP_i(const GROUP_i & g):_group(g._group),
		   SUPPORT_i(g._group)
{
	BEGIN_OF("Constructor GROUP_i");
        END_OF("Constructor GROUP_i");
};
//=============================================================================
/*!
 * CORBA: Number of Families existing in the group
 */
//=============================================================================

CORBA::Long  GROUP_i::getNumberOfFamilies() 
throw (SALOME::SALOME_Exception)
{
        if (_group==NULL)
                THROW_SALOME_CORBA_EXCEPTION("No associated Group",\
					     SALOME::INTERNAL_ERROR);
        try
        {
                return _group->getNumberOfFamilies();
        }
        catch (MEDEXCEPTION &ex)
        {
                MESSAGE("Unable to get number of families of the group");
		THROW_SALOME_CORBA_EXCEPTION(ex.what(), SALOME::INTERNAL_ERROR);
        }
};
//=============================================================================
/*!
 * CORBA: Returns references for families within the group
 */
//=============================================================================

SALOME_MED::Family_array* GROUP_i::getFamilies() 	 
throw (SALOME::SALOME_Exception)
{
        if (_group==NULL)
                THROW_SALOME_CORBA_EXCEPTION("No associated Group",\
					     SALOME::INTERNAL_ERROR);
	SALOME_MED::Family_array_var myseq = new SALOME_MED::Family_array;
	try
        {
                int nbfam= _group->getNumberOfFamilies();
		myseq->length(nbfam);
		vector<FAMILY*> fam(nbfam);
	 	fam = _group->getFamilies();
		for (int i=0;i<nbfam;i++)
                {
			FAMILY_i * f1=new FAMILY_i(fam[i]);
		        SALOME_MED::FAMILY_ptr f2 = 
					f1->POA_SALOME_MED::FAMILY::_this();
			f1->_remove_ref();
			myseq[i] = f2;
		}
	}
	catch (MEDEXCEPTION &ex)
	{
                MESSAGE("Unable to access families");
		THROW_SALOME_CORBA_EXCEPTION(ex.what(), SALOME::INTERNAL_ERROR);
        }
	return myseq._retn();
};
//=============================================================================
/*!
 * CORBA: Returns reference for family I within the group
 */
//=============================================================================

SALOME_MED::FAMILY_ptr GROUP_i::getFamily(CORBA::Long i) 
throw (SALOME::SALOME_Exception)
{
        if (_group==NULL)
                THROW_SALOME_CORBA_EXCEPTION("No associated Group",\
					     SALOME::INTERNAL_ERROR);
	try
        {
		FAMILY * fam=_group->getFamily(i);
		FAMILY_i * f1=new FAMILY_i(fam);
		SALOME_MED::FAMILY_ptr f2 = f1->POA_SALOME_MED::FAMILY::_this();
		f1->_remove_ref();
		return (SALOME_MED::FAMILY::_duplicate(f2));
	}
	catch (MEDEXCEPTION &ex)
	{
                MESSAGE("Unable to acces to the specified family");
		THROW_SALOME_CORBA_EXCEPTION(ex.what(), SALOME::INTERNAL_ERROR);
        }
};