// Copyright (C) 2007-2014  CEA/DEN, EDF R&D
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
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
// Author : Anthony Geay (CEA/DEN)

#include "MEDCouplingIMesh.hxx"
#include "MEDCouplingCMesh.hxx"
#include "MEDCouplingMemArray.hxx"
#include "MEDCouplingFieldDouble.hxx"

#include <functional>
#include <algorithm>
#include <sstream>
#include <numeric>

using namespace ParaMEDMEM;

MEDCouplingIMesh::MEDCouplingIMesh():_space_dim(-1)
{
  _origin[0]=0.; _origin[1]=0.; _origin[2]=0.;
  _dxyz[0]=0.; _dxyz[1]=0.; _dxyz[2]=0.;
  _structure[0]=0; _structure[1]=0; _structure[2]=0;
}

MEDCouplingIMesh::MEDCouplingIMesh(const MEDCouplingIMesh& other, bool deepCopy):MEDCouplingStructuredMesh(other,deepCopy),_space_dim(other._space_dim),_axis_unit(other._axis_unit)
{
  _origin[0]=other._origin[0]; _origin[1]=other._origin[1]; _origin[2]=other._origin[2];
  _dxyz[0]=other._dxyz[0]; _dxyz[1]=other._dxyz[1]; _dxyz[2]=other._dxyz[2];
  _structure[0]=other._structure[0]; _structure[1]=other._structure[1]; _structure[2]=other._structure[2];
}

MEDCouplingIMesh::~MEDCouplingIMesh()
{
}

MEDCouplingIMesh *MEDCouplingIMesh::New()
{
  return new MEDCouplingIMesh;
}

MEDCouplingIMesh *MEDCouplingIMesh::New(const std::string& meshName, int spaceDim, const int *nodeStrctStart, const int *nodeStrctStop,
                                        const double *originStart, const double *originStop, const double *dxyzStart, const double *dxyzStop)
{
  MEDCouplingAutoRefCountObjectPtr<MEDCouplingIMesh> ret(new MEDCouplingIMesh);
  ret->setName(meshName);
  ret->setSpaceDimension(spaceDim);
  ret->setNodeStruct(nodeStrctStart,nodeStrctStop);
  ret->setOrigin(originStart,originStop);
  ret->setDXYZ(dxyzStart,dxyzStop);
  return ret.retn();
}

MEDCouplingMesh *MEDCouplingIMesh::deepCpy() const
{
  return clone(true);
}

MEDCouplingIMesh *MEDCouplingIMesh::clone(bool recDeepCpy) const
{
  return new MEDCouplingIMesh(*this,recDeepCpy);
}

void MEDCouplingIMesh::setNodeStruct(const int *nodeStrctStart, const int *nodeStrctStop)
{
  checkSpaceDimension();
  int sz((int)std::distance(nodeStrctStart,nodeStrctStop));
  if(sz!=_space_dim)
    throw INTERP_KERNEL::Exception("MEDCouplingIMesh::setNodeStruct : input vector of node structure has not the right size ! Or change space dimension before calling it !");
  std::copy(nodeStrctStart,nodeStrctStop,_structure);
  declareAsNew();
}

std::vector<int> MEDCouplingIMesh::getNodeStruct() const
{
  checkSpaceDimension();
  return std::vector<int>(_structure,_structure+_space_dim);
}

void MEDCouplingIMesh::setOrigin(const double *originStart, const double *originStop)
{
  checkSpaceDimension();
  int sz((int)std::distance(originStart,originStop));
  if(sz!=_space_dim)
    throw INTERP_KERNEL::Exception("MEDCouplingIMesh::setOrigin : input vector of origin vector has not the right size ! Or change space dimension before calling it !");
  std::copy(originStart,originStop,_origin);
  declareAsNew();
}

std::vector<double> MEDCouplingIMesh::getOrigin() const
{
  checkSpaceDimension();
  return std::vector<double>(_origin,_origin+_space_dim);
}

void MEDCouplingIMesh::setDXYZ(const double *dxyzStart, const double *dxyzStop)
{
  checkSpaceDimension();
  int sz((int)std::distance(dxyzStart,dxyzStop));
  if(sz!=_space_dim)
    throw INTERP_KERNEL::Exception("MEDCouplingIMesh::setDXYZ : input vector of dxyz vector has not the right size ! Or change space dimension before calling it !");
  std::copy(dxyzStart,dxyzStop,_dxyz);
  declareAsNew();
}

std::vector<double> MEDCouplingIMesh::getDXYZ() const
{
  checkSpaceDimension();
  return std::vector<double>(_dxyz,_dxyz+_space_dim);
}

void MEDCouplingIMesh::setAxisUnit(const std::string& unitName)
{
  _axis_unit=unitName;
  declareAsNew();
}

std::string MEDCouplingIMesh::getAxisUnit() const
{
  return _axis_unit;
}

/*!
 * This method returns the measure of any cell in \a this.
 * This specific method of image grid mesh utilizes the fact that any cell in \a this have the same measure.
 * The value returned by this method is those used to feed the returned field in the MEDCouplingIMesh::getMeasureField.
 *
 * \sa getMeasureField
 */
double MEDCouplingIMesh::getMeasureOfAnyCell() const
{
  checkCoherency();
  int dim(getSpaceDimension());
  double ret(1.);
  for(int i=0;i<dim;i++)
    ret*=fabs(_dxyz[i]);
  return ret;
}

/*!
 * This method is allows to convert \a this into MEDCouplingCMesh instance.
 * This method is the middle level between MEDCouplingIMesh and the most general MEDCouplingUMesh.
 * This method is useful for MED writers that do not have still the image grid support.
 *
 * \sa MEDCouplingMesh::buildUnstructured
 */
MEDCouplingCMesh *MEDCouplingIMesh::convertToCartesian() const
{
  checkCoherency();
  MEDCouplingAutoRefCountObjectPtr<MEDCouplingCMesh> ret(MEDCouplingCMesh::New());
  try
  { ret->copyTinyInfoFrom(this); }
  catch(INTERP_KERNEL::Exception& e) { }
  int spaceDim(getSpaceDimension());
  std::vector<std::string> infos(buildInfoOnComponents());
  for(int i=0;i<spaceDim;i++)
    {
      MEDCouplingAutoRefCountObjectPtr<DataArrayDouble> arr(DataArrayDouble::New()); arr->alloc(_structure[i],1); arr->setInfoOnComponent(0,infos[i]);
      arr->iota(); arr->applyLin(_dxyz[i],_origin[i]);
      ret->setCoordsAt(i,arr);
    }
  return ret.retn();
}

void MEDCouplingIMesh::setSpaceDimension(int spaceDim)
{
  if(spaceDim==_space_dim)
    return ;
  CheckSpaceDimension(spaceDim);
  _space_dim=spaceDim;
  declareAsNew();
}

void MEDCouplingIMesh::updateTime() const
{
}

std::size_t MEDCouplingIMesh::getHeapMemorySizeWithoutChildren() const
{
  return MEDCouplingStructuredMesh::getHeapMemorySizeWithoutChildren();
}

std::vector<const BigMemoryObject *> MEDCouplingIMesh::getDirectChildren() const
{
  return std::vector<const BigMemoryObject *>();
}

/*!
 * This method copyies all tiny strings from other (name and components name).
 * @throw if other and this have not same mesh type.
 */
void MEDCouplingIMesh::copyTinyStringsFrom(const MEDCouplingMesh *other)
{ 
  const MEDCouplingIMesh *otherC=dynamic_cast<const MEDCouplingIMesh *>(other);
  if(!otherC)
    throw INTERP_KERNEL::Exception("MEDCouplingIMesh::copyTinyStringsFrom : meshes have not same type !");
  MEDCouplingStructuredMesh::copyTinyStringsFrom(other);
  declareAsNew();
}

bool MEDCouplingIMesh::isEqualIfNotWhy(const MEDCouplingMesh *other, double prec, std::string& reason) const
{
  if(!other)
    throw INTERP_KERNEL::Exception("MEDCouplingIMesh::isEqualIfNotWhy : input other pointer is null !");
  const MEDCouplingIMesh *otherC(dynamic_cast<const MEDCouplingIMesh *>(other));
  if(!otherC)
    {
      reason="mesh given in input is not castable in MEDCouplingIMesh !";
      return false;
    }
  if(!MEDCouplingStructuredMesh::isEqualIfNotWhy(other,prec,reason))
    return false;
  if(!isEqualWithoutConsideringStrInternal(otherC,prec,reason))
    return false;
  if(_axis_unit!=otherC->_axis_unit)
    {
      reason="The units of axis are not the same !";
      return false;
    }
  return true;
}

bool MEDCouplingIMesh::isEqualWithoutConsideringStr(const MEDCouplingMesh *other, double prec) const
{
  const MEDCouplingIMesh *otherC=dynamic_cast<const MEDCouplingIMesh *>(other);
  if(!otherC)
    return false;
  std::string tmp;
  return isEqualWithoutConsideringStrInternal(other,prec,tmp);
}

bool MEDCouplingIMesh::isEqualWithoutConsideringStrInternal(const MEDCouplingMesh *other, double prec, std::string& reason) const
{
  const MEDCouplingIMesh *otherC=dynamic_cast<const MEDCouplingIMesh *>(other);
  if(!otherC)
    return false;
  if(_space_dim!=otherC->_space_dim)
    {
      std::ostringstream oss;
      oss << "The spaceDimension of this (" << _space_dim << ") is not equal to those of other (" << otherC->_space_dim << ") !";
      return false;
    }
  checkSpaceDimension();
  for(int i=0;i<_space_dim;i++)
    {
      if(fabs(_origin[i]-otherC->_origin[i])>prec)
        {
          std::ostringstream oss;
          oss << "The origin of this and other differs at " << i << " !";
          reason=oss.str();
          return false;
        }
    }
  for(int i=0;i<_space_dim;i++)
    {
      if(fabs(_dxyz[i]-otherC->_dxyz[i])>prec)
        {
          std::ostringstream oss;
          oss << "The delta of this and other differs at " << i << " !";
          reason=oss.str();
          return false;
        }
    }
  for(int i=0;i<_space_dim;i++)
    {
      if(_structure[i]!=otherC->_structure[i])
        {
          std::ostringstream oss;
          oss << "The structure of this and other differs at " << i << " !";
          reason=oss.str();
          return false;
        }
    }
  return true;
}

void MEDCouplingIMesh::checkDeepEquivalWith(const MEDCouplingMesh *other, int cellCompPol, double prec,
                                            DataArrayInt *&cellCor, DataArrayInt *&nodeCor) const
{
  if(!isEqualWithoutConsideringStr(other,prec))
    throw INTERP_KERNEL::Exception("MEDCouplingIMesh::checkDeepEquivalWith : Meshes are not the same !");
}

/*!
 * Nothing is done here (except to check that the other is a ParaMEDMEM::MEDCouplingIMesh instance too).
 * The user intend that the nodes are the same, so by construction of ParaMEDMEM::MEDCouplingIMesh, \a this and \a other are the same !
 */
void MEDCouplingIMesh::checkDeepEquivalOnSameNodesWith(const MEDCouplingMesh *other, int cellCompPol, double prec,
                                                       DataArrayInt *&cellCor) const
{
  if(!isEqualWithoutConsideringStr(other,prec))
    throw INTERP_KERNEL::Exception("MEDCouplingIMesh::checkDeepEquivalOnSameNodesWith : Meshes are not the same !");
}

void MEDCouplingIMesh::checkCoherency() const
{
  checkSpaceDimension();
  for(int i=0;i<_space_dim;i++)
    if(_structure[i]<1)
      {
        std::ostringstream oss; oss << "MEDCouplingIMesh::checkCoherency : On axis " << i << "/" << _space_dim << ", number of nodes is equal to " << _structure[i] << " ! must be >=1 !";
        throw INTERP_KERNEL::Exception(oss.str().c_str());
      }
}

void MEDCouplingIMesh::checkCoherency1(double eps) const
{
  checkCoherency();
}

void MEDCouplingIMesh::checkCoherency2(double eps) const
{
  checkCoherency1(eps);
}

void MEDCouplingIMesh::getSplitCellValues(int *res) const
{
  int meshDim(getMeshDimension());
  for(int l=0;l<meshDim;l++)
    {
      int val=1;
      for(int p=0;p<meshDim-l-1;p++)
        val*=_structure[p]-1;
      res[meshDim-l-1]=val;
    }
}

void MEDCouplingIMesh::getSplitNodeValues(int *res) const
{
  int spaceDim(getSpaceDimension());
  for(int l=0;l<spaceDim;l++)
    {
      int val=1;
      for(int p=0;p<spaceDim-l-1;p++)
        val*=_structure[p];
      res[spaceDim-l-1]=val;
    }
}

void MEDCouplingIMesh::getNodeGridStructure(int *res) const
{
  checkSpaceDimension();
  std::copy(_structure,_structure+_space_dim,res);
}

std::vector<int> MEDCouplingIMesh::getNodeGridStructure() const
{
  checkSpaceDimension();
  std::vector<int> ret(_structure,_structure+_space_dim);
  return ret;
}

MEDCouplingStructuredMesh *MEDCouplingIMesh::buildStructuredSubPart(const std::vector< std::pair<int,int> >& cellPart) const
{
  checkCoherency();
  int dim(getSpaceDimension());
  if(dim!=(int)cellPart.size())
    {
      std::ostringstream oss; oss << "MEDCouplingIMesh::buildStructuredSubPart : the space dimension is " << dim << " and cell part size is " << cellPart.size() << " !";
      throw INTERP_KERNEL::Exception(oss.str().c_str());
    }
  double retOrigin[3]={0.,0.,0.};
  int retStruct[3]={0,0,0};
  MEDCouplingAutoRefCountObjectPtr<MEDCouplingIMesh> ret(dynamic_cast<MEDCouplingIMesh *>(deepCpy()));
  for(int i=0;i<dim;i++)
    {
      int startNode(cellPart[i].first),endNode(cellPart[i].second+1);
      int myDelta(endNode-startNode);
      if(startNode<0 || startNode>=_structure[i])
        {
          std::ostringstream oss; oss << "MEDCouplingIMesh::buildStructuredSubPart : At dimension #" << i << " the start node id is " << startNode << " it should be in [0," << _structure[i] << ") !";
          throw INTERP_KERNEL::Exception(oss.str().c_str());
        }
      if(myDelta<0 || myDelta>_structure[i])
        {
          std::ostringstream oss; oss << "MEDCouplingIMesh::buildStructuredSubPart : Along dimension #" << i << " the number of nodes is " << _structure[i] << ", and you are requesting for " << myDelta << " nodes wide range !" << std::endl;
          throw INTERP_KERNEL::Exception(oss.str().c_str());
        }
      retOrigin[i]=_origin[i]+startNode*_dxyz[i];
      retStruct[i]=myDelta;
    }
  ret->setNodeStruct(retStruct,retStruct+dim);
  ret->setOrigin(retOrigin,retOrigin+dim);
  ret->checkCoherency();
  return ret.retn();
}

/*!
 * Return the space dimension of \a this.
 */
int MEDCouplingIMesh::getSpaceDimension() const
{
  return _space_dim;
}

void MEDCouplingIMesh::getCoordinatesOfNode(int nodeId, std::vector<double>& coo) const
{
  int tmp[3];
  int spaceDim(getSpaceDimension());
  getSplitNodeValues(tmp);
  int tmp2[3];
  GetPosFromId(nodeId,spaceDim,tmp,tmp2);
  for(int j=0;j<spaceDim;j++)
    coo.push_back(_origin[j]+_dxyz[j]*tmp2[j]);
}

std::string MEDCouplingIMesh::simpleRepr() const
{
  std::ostringstream ret;
  ret << "Image grid with name : \"" << getName() << "\"\n";
  ret << "Description of mesh : \"" << getDescription() << "\"\n";
  int tmpp1,tmpp2;
  double tt(getTime(tmpp1,tmpp2));
  int spaceDim(_space_dim);
  ret << "Time attached to the mesh [unit] : " << tt << " [" << getTimeUnit() << "]\n";
  ret << "Iteration : " << tmpp1  << " Order : " << tmpp2 << "\n";
  ret << "Space dimension : " << spaceDim << "\n";
  if(spaceDim<0 || spaceDim>3)
    return ret.str();
  ret << "The nodal structure is : "; std::copy(_structure,_structure+spaceDim,std::ostream_iterator<int>(ret," ")); ret << "\n";
  ret << "The origin position is [" << _axis_unit << "]: ";
  std::copy(_origin,_origin+spaceDim,std::ostream_iterator<double>(ret," ")); ret << "\n";
  ret << "The intervals along axis are : ";
  std::copy(_dxyz,_dxyz+spaceDim,std::ostream_iterator<double>(ret," ")); ret << "\n";
  return ret.str();
}

std::string MEDCouplingIMesh::advancedRepr() const
{
  return simpleRepr();
}

void MEDCouplingIMesh::getBoundingBox(double *bbox) const
{
  checkCoherency();
  int dim(getSpaceDimension());
  for(int idim=0; idim<dim; idim++)
    {
      bbox[2*idim]=_origin[idim];
      bbox[2*idim+1]=_origin[idim]+_dxyz[idim]*_structure[idim];
    }
}

/*!
 * Returns a new MEDCouplingFieldDouble containing volumes of cells constituting \a this
 * mesh.<br>
 * For 1D cells, the returned field contains lengths.<br>
 * For 2D cells, the returned field contains areas.<br>
 * For 3D cells, the returned field contains volumes.
 *  \param [in] isAbs - a not used parameter.
 *  \return MEDCouplingFieldDouble * - a new instance of MEDCouplingFieldDouble on cells
 *         and one time . The caller is to delete this field using decrRef() as it is no
 *         more needed.
 */
MEDCouplingFieldDouble *MEDCouplingIMesh::getMeasureField(bool isAbs) const
{
  checkCoherency();
  std::string name="MeasureOfMesh_";
  name+=getName();
  int nbelem(getNumberOfCells());
  MEDCouplingFieldDouble *field(MEDCouplingFieldDouble::New(ON_CELLS,ONE_TIME));
  field->setName(name);
  DataArrayDouble* array(DataArrayDouble::New());
  array->alloc(nbelem,1);
  array->fillWithValue(getMeasureOfAnyCell());
  field->setArray(array) ;
  array->decrRef();
  field->setMesh(const_cast<MEDCouplingIMesh *>(this));
  field->synchronizeTimeWithMesh();
  return field;
}

/*!
 * not implemented yet !
 */
MEDCouplingFieldDouble *MEDCouplingIMesh::getMeasureFieldOnNode(bool isAbs) const
{
  throw INTERP_KERNEL::Exception("MEDCouplingIMesh::getMeasureFieldOnNode : not implemented yet !");
  //return 0;
}

int MEDCouplingIMesh::getCellContainingPoint(const double *pos, double eps) const
{
  int dim(getSpaceDimension()),ret(0),coeff(1);
  for(int i=0;i<dim;i++)
    {
      int nbOfCells(_structure[i]-1);
      double ref(pos[i]);
      int tmp((ref-_origin[i])/_dxyz[i]);
      if(tmp>=0 && tmp<nbOfCells)
        {
          ret+=coeff*tmp;
          coeff*=nbOfCells;
        }
      else
        return -1;
    }
  return ret;
}

void MEDCouplingIMesh::rotate(const double *center, const double *vector, double angle)
{
  throw INTERP_KERNEL::Exception("No rotation available on IMesh : Traduce it to unstructured mesh to apply it !");
}

/*!
 * Translates all nodes of \a this mesh by a given vector. Actually, it adds each
 * component of the \a vector to all node coordinates of a corresponding axis.
 *  \param [in] vector - the translation vector whose size must be not less than \a
 *         this->getSpaceDimension().
 */
void MEDCouplingIMesh::translate(const double *vector)
{
  checkSpaceDimension();
  int dim(getSpaceDimension());
  std::transform(_origin,_origin+dim,vector,_origin,std::plus<double>());
  declareAsNew();
}

/*!
 * Applies scaling transformation to all nodes of \a this mesh.
 *  \param [in] point - coordinates of a scaling center. This array is to be of
 *         size \a this->getSpaceDimension() at least.
 *  \param [in] factor - a scale factor.
 */
void MEDCouplingIMesh::scale(const double *point, double factor)
{
  checkSpaceDimension();
  int dim(getSpaceDimension());
  std::transform(_origin,_origin+dim,point,_origin,std::minus<double>());
  std::transform(_origin,_origin+dim,_origin,std::bind2nd(std::multiplies<double>(),factor));
  std::transform(_dxyz,_dxyz+dim,_dxyz,std::bind2nd(std::multiplies<double>(),factor));
  std::transform(_origin,_origin+dim,point,_origin,std::plus<double>());
  declareAsNew();
}

MEDCouplingMesh *MEDCouplingIMesh::mergeMyselfWith(const MEDCouplingMesh *other) const
{
  //not implemented yet !
  return 0;
}

/*!
 * Returns a new DataArrayDouble holding coordinates of all nodes of \a this mesh.
 *  \return DataArrayDouble * - a new instance of DataArrayDouble, of size \a
 *          this->getNumberOfNodes() tuples per \a this->getSpaceDimension()
 *          components. The caller is to delete this array using decrRef() as it is
 *          no more needed.
 */
DataArrayDouble *MEDCouplingIMesh::getCoordinatesAndOwner() const
{
  checkCoherency();
  MEDCouplingAutoRefCountObjectPtr<DataArrayDouble> ret(DataArrayDouble::New());
  int spaceDim(getSpaceDimension()),nbNodes(getNumberOfNodes());
  ret->alloc(nbNodes,spaceDim);
  double *pt(ret->getPointer());
  ret->setInfoOnComponents(buildInfoOnComponents());
  int tmp2[3],tmp[3];
  getSplitNodeValues(tmp);
  for(int i=0;i<nbNodes;i++)
    {
      GetPosFromId(i,spaceDim,tmp,tmp2);
      for(int j=0;j<spaceDim;j++)
        pt[i*spaceDim+j]=_dxyz[j]*tmp2[j]+_origin[j];
    }
  return ret.retn();
}

/*!
 * Returns a new DataArrayDouble holding barycenters of all cells. The barycenter is
 * computed by averaging coordinates of cell nodes.
 *  \return DataArrayDouble * - a new instance of DataArrayDouble, of size \a
 *          this->getNumberOfCells() tuples per \a this->getSpaceDimension()
 *          components. The caller is to delete this array using decrRef() as it is
 *          no more needed.
 */
DataArrayDouble *MEDCouplingIMesh::getBarycenterAndOwner() const
{
  checkCoherency();
  MEDCouplingAutoRefCountObjectPtr<DataArrayDouble> ret(DataArrayDouble::New());
  int spaceDim(getSpaceDimension()),nbCells(getNumberOfCells()),tmp[3],tmp2[3];
  ret->alloc(nbCells,spaceDim);
  double *pt(ret->getPointer()),shiftOrigin[3];
  std::transform(_dxyz,_dxyz+spaceDim,shiftOrigin,std::bind2nd(std::multiplies<double>(),0.5));
  std::transform(_origin,_origin+spaceDim,shiftOrigin,shiftOrigin,std::plus<double>());
  getSplitCellValues(tmp);
  ret->setInfoOnComponents(buildInfoOnComponents());
  for(int i=0;i<nbCells;i++)
    {
      GetPosFromId(i,spaceDim,tmp,tmp2);
      for(int j=0;j<spaceDim;j++)
        pt[i*spaceDim+j]=_dxyz[j]*tmp2[j]+shiftOrigin[j];
    }
  return ret.retn();
}

DataArrayDouble *MEDCouplingIMesh::computeIsoBarycenterOfNodesPerCell() const
{
  return MEDCouplingIMesh::getBarycenterAndOwner();
}

void MEDCouplingIMesh::renumberCells(const int *old2NewBg, bool check)
{
  throw INTERP_KERNEL::Exception("Functionnality of renumbering cell not available for IMesh !");
}

void MEDCouplingIMesh::getTinySerializationInformation(std::vector<double>& tinyInfoD, std::vector<int>& tinyInfo, std::vector<std::string>& littleStrings) const
{
  int it,order;
  double time(getTime(it,order));
  tinyInfo.clear();
  tinyInfoD.clear();
  littleStrings.clear();
  littleStrings.push_back(getName());
  littleStrings.push_back(getDescription());
  littleStrings.push_back(getTimeUnit());
  littleStrings.push_back(getAxisUnit());
  tinyInfo.push_back(it);
  tinyInfo.push_back(order);
  tinyInfo.push_back(_space_dim);
  tinyInfo.insert(tinyInfo.end(),_structure,_structure+3);
  tinyInfoD.push_back(time);
  tinyInfoD.insert(tinyInfoD.end(),_dxyz,_dxyz+3);
  tinyInfoD.insert(tinyInfoD.end(),_origin,_origin+3);
}

void MEDCouplingIMesh::resizeForUnserialization(const std::vector<int>& tinyInfo, DataArrayInt *a1, DataArrayDouble *a2, std::vector<std::string>& littleStrings) const
{
  a1->alloc(0,1);
  a2->alloc(0,1);
}

void MEDCouplingIMesh::serialize(DataArrayInt *&a1, DataArrayDouble *&a2) const
{
  a1=DataArrayInt::New();
  a1->alloc(0,1);
  a2=DataArrayDouble::New();
  a2->alloc(0,1);
}

void MEDCouplingIMesh::unserialization(const std::vector<double>& tinyInfoD, const std::vector<int>& tinyInfo, const DataArrayInt *a1, DataArrayDouble *a2,
                                       const std::vector<std::string>& littleStrings)
{
  setName(littleStrings[0]);
  setDescription(littleStrings[1]);
  setTimeUnit(littleStrings[2]);
  setAxisUnit(littleStrings[3]);
  setTime(tinyInfoD[0],tinyInfo[0],tinyInfo[1]);
  _space_dim=tinyInfo[2];
  _structure[0]=tinyInfo[3]; _structure[1]=tinyInfo[4]; _structure[2]=tinyInfo[5];
  _dxyz[0]=tinyInfoD[1]; _dxyz[1]=tinyInfoD[2]; _dxyz[2]=tinyInfoD[3];
  _origin[0]=tinyInfoD[4]; _origin[1]=tinyInfoD[5]; _origin[2]=tinyInfoD[6];
  declareAsNew();
}

void MEDCouplingIMesh::writeVTKLL(std::ostream& ofs, const std::string& cellData, const std::string& pointData, DataArrayByte *byteData) const
{
  checkCoherency();
  std::ostringstream extent,origin,spacing;
  for(int i=0;i<3;i++)
    {
      if(i<_space_dim)
        { extent << "0 " <<  _structure[i]-1 << " "; origin << _origin[i] << " "; spacing << _dxyz[i] << " "; }
      else
        { extent << "0 0 "; origin << "0 "; spacing << "0 "; }
    }
  ofs << "  <" << getVTKDataSetType() << " WholeExtent=\"" << extent.str() << "\" Origin=\"" << origin.str() << "\" Spacing=\"" << spacing.str() << "\">\n";
  ofs << "    <Piece Extent=\"" << extent.str() << "\">\n";
  ofs << "      <PointData>\n" << pointData << std::endl;
  ofs << "      </PointData>\n";
  ofs << "      <CellData>\n" << cellData << std::endl;
  ofs << "      </CellData>\n";
  ofs << "      <Coordinates>\n";
  ofs << "      </Coordinates>\n";
  ofs << "    </Piece>\n";
  ofs << "  </" << getVTKDataSetType() << ">\n";
}

void MEDCouplingIMesh::reprQuickOverview(std::ostream& stream) const
{
  stream << "MEDCouplingIMesh C++ instance at " << this << ". Name : \"" << getName() << "\". Space dimension : " << _space_dim << ".";
  if(_space_dim<0 || _space_dim>3)
    return ;
  stream << "\n";
  std::ostringstream stream0,stream1;
  int nbNodes(1),nbCells(0);
  bool isPb(false);
  for(int i=0;i<_space_dim;i++)
    {
      char tmp('X'+i);
      int tmpNodes(_structure[i]);
      stream1 << "- Axis " << tmp << " : " << tmpNodes << " nodes (orig=" << _origin[i] << ", inter=" << _dxyz[i] << ").";
      if(i!=_space_dim-1)
        stream1 << std::endl;
      if(tmpNodes>=1)
        nbNodes*=tmpNodes;
      else
        isPb=true;
      if(tmpNodes>=2)
        nbCells=nbCells==0?tmpNodes-1:nbCells*(tmpNodes-1);
    }
  if(!isPb)
    {
      stream0 << "Number of cells : " << nbCells << ", Number of nodes : " << nbNodes;
      stream << stream0.str();
      if(_space_dim>0)
        stream << std::endl;
    }
  stream << stream1.str();
}

std::string MEDCouplingIMesh::getVTKDataSetType() const
{
  return std::string("ImageData");
}

std::vector<std::string> MEDCouplingIMesh::buildInfoOnComponents() const
{
  checkSpaceDimension();
  int dim(getSpaceDimension());
  std::vector<std::string> ret(dim);
  for(int i=0;i<dim;i++)
    {
      std::ostringstream oss;
      char tmp('X'+i); oss << tmp;
      ret[i]=DataArray::BuildInfoFromVarAndUnit(oss.str(),_axis_unit);
    }
  return ret;
}

void MEDCouplingIMesh::checkSpaceDimension() const
{
  CheckSpaceDimension(_space_dim);
}

void MEDCouplingIMesh::CheckSpaceDimension(int spaceDim)
{
  if(spaceDim<0 || spaceDim>3)
    throw INTERP_KERNEL::Exception("MEDCouplingIMesh::CheckSpaceDimension : input spaceDim must be in [0,1,2,3] !");
}
