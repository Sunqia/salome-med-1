//  MED MEDMEM : MED files in memory
//
//  Copyright (C) 2003  CEA/DEN, EDF R&D
//
//
//
//  File   : MEDMEM_Grid.hxx
//  Author : Edward AGAPOV (eap)
//  Module : MED
//  $Header$

using namespace std;
#include "MEDMEM_Grid.hxx"
#include <MEDMEM_CellModel.hxx>
#include <MEDMEM_SkyLineArray.hxx>

//=======================================================================
//function : GRID
//purpose  : empty constructor
//=======================================================================

GRID::GRID() {
  init();
  MESSAGE("A GRID CREATED");
}

//=======================================================================
//function : GRID
//purpose  : empty constructor
//=======================================================================

GRID::GRID(const med_grid_type type)
{
  init();
  _gridType = type;
  MESSAGE("A TYPED GRID CREATED");
}

//=======================================================================
//function : GRID
//purpose  : copying constructor
//=======================================================================

GRID::GRID(const GRID& otherGrid) {
  *this = otherGrid;
}

//=======================================================================
//function : ~GRID
//purpose  : destructor
//=======================================================================

GRID::~GRID() {
  MESSAGE("GRID::~GRID() : Destroying the Grid");
  if ( _iArray != (double* ) NULL) delete [] _iArray;
  if ( _jArray != (double* ) NULL) delete [] _jArray;
  if ( _kArray != (double* ) NULL) delete [] _kArray;
}

//=======================================================================
//function : init
//purpose : 
//=======================================================================

void GRID::init()
{
  _gridType = MED_CARTESIAN;
    
  _iArray = _jArray = _kArray = (double* ) NULL;
  _iArrayLength = _jArrayLength = _kArrayLength = 0;

  _is_coordinates_filled  = false;
  _is_connectivity_filled = false;

  MESH::init();

  _isAGrid = true;
}

//=======================================================================
//function: operator=
//purpose : operator=
//=======================================================================

GRID & GRID::operator=(const GRID & otherGrid)
{
  // NOT IMPLEMENTED

  MESH::operator=(otherGrid);
  return *this;
}

//=======================================================================
//function : GRID
//purpose  : Create a GRID object using a MESH driver of type
//           (MED_DRIVER, ....) associated with file <fileName>. 
//=======================================================================

GRID::GRID(driverTypes driverType,
           const string &  fileName,
           const string &  driverName) {
  const char * LOC ="GRID::GRID(driverTypes , const string &  , const string &) : ";
  
  BEGIN_OF(LOC);
  
//  int current;

  init();
  MESH(driverType,fileName,driverName);

//   current = addDriver(driverType,fileName,driverName);
  
//   switch(_drivers[current]->getAccessMode() ) {
//   case MED_RDONLY :
//     MESSAGE(LOC << "driverType must have a MED_RDWR accessMode");
//     rmDriver(current);
//     break;
//   default: {}
//   }
//   _drivers[current]->open();   
//   _drivers[current]->read();
//   _drivers[current]->close();

//   // fill some fields of MESH
//   fillMeshAfterRead();
    
  END_OF(LOC);
};

//=======================================================================
//function : fillMeshAfterRead
//purpose  : 
//=======================================================================

void GRID::fillMeshAfterRead()
{
 // fill not only MESH  (:-)
  _is_coordinates_filled  = false;
  _is_connectivity_filled = false;

  if (_gridType == MED_BODY_FITTED)
  {
    _is_coordinates_filled = true;

    // nb of nodes in each direction is not known, set anything
    // in order to be able to work anyhow
//     INFOS("GRID::fillMeshAfterRead(): This stub must be removed");
//     switch (_spaceDimension) {
//     case 1:
//       _iArrayLength = _numberOfNodes;
//       _jArrayLength = 0;
//       _kArrayLength = 0;
//       break;
//     case 2:
//       _iArrayLength = 2;
//       _jArrayLength = _numberOfNodes / _iArrayLength;
//       _kArrayLength = 0;
//       break;
//     default:
//       _iArrayLength = 2;
//       _jArrayLength = _numberOfNodes / _iArrayLength / 2;
//       _kArrayLength = _numberOfNodes / _iArrayLength / _jArrayLength;
//     }
    //cout << "ARRAY LENGTHS: " << _iArrayLength << " " << _jArrayLength
//      << " " << _kArrayLength << endl;
  }
//   else {
//     int NbNodes = _iArrayLength;
//     if (_jArrayLength)
//       NbNodes *= _jArrayLength;
//     if (_kArrayLength)
//       NbNodes *= _kArrayLength;
//     MESH::_numberOfNodes = NbNodes;
//   }

  MESH::_meshDimension = MESH::_spaceDimension;
}

//=======================================================================
//function : fillCoordinates
//purpose  : 
//=======================================================================

void GRID::fillCoordinates()
{
  if (_is_coordinates_filled)
  {
    MESSAGE("GRID::fillCoordinates(): Already filled");
    return;
  }
  
  const char * LOC ="GRID::fillCoordinates()";
  BEGIN_OF(LOC);
  
  double* myCoord =
    const_cast <double *> ( _coordinate->getCoordinates(MED_FULL_INTERLACE) );

  bool hasJ = _jArrayLength, hasK = _kArrayLength;
  int J = hasJ ? _jArrayLength : 1;
  int K = hasK ? _kArrayLength : 1;
  int nb, i, j, k;
  for (k=0; k < K; ++k) {
    for (j=0; j < J; ++j) {
      for (i=0; i < _iArrayLength; ++i) {
        
        * myCoord = _iArray[ i ];
        ++ myCoord;
        
        if (hasJ)
        {
          * myCoord = _jArray[ j ];
          ++ myCoord;
          
          if (hasK)
          {
            * myCoord = _jArray[ k ];
            ++ myCoord;
          }
        }
      }
    }
  }
      
  _is_coordinates_filled = true;
  END_OF(LOC);
}

//=======================================================================
//function : makeConnectivity
//purpose  : 
//=======================================================================

CONNECTIVITY * GRID::makeConnectivity (const medEntityMesh           Entity,
                                            const medGeometryElement Geometry,
                                            const int                NbEntities,
                                            const int                NbNodes,
                                            int *                    NodeNumbers)
{
  CONNECTIVITY * Connectivity     = new CONNECTIVITY(Entity) ;
  Connectivity->_numberOfNodes    = NbNodes ;
  Connectivity->_entityDimension  = Geometry/100 ;
  
  int numberOfGeometricType    = 1;
  Connectivity->_numberOfTypes = numberOfGeometricType;

  Connectivity->_count    = new int [numberOfGeometricType + 1] ;
  Connectivity->_count[0] = 1;
  Connectivity->_count[1] = 1 + NbEntities;

  Connectivity->_type    = new CELLMODEL [numberOfGeometricType];
  Connectivity->_type[0] = CELLMODEL( Geometry ) ;

  Connectivity->_geometricTypes    = new medGeometryElement [ numberOfGeometricType ];
  Connectivity->_geometricTypes[0] = Geometry;

  //  Connectivity->_nodal = new MEDSKYLINEARRAY() ;
  int * skyLineArrayIndex = new int [NbEntities + 1];
  int i, j, nbEntityNodes = Connectivity->_type[0].getNumberOfNodes();
  for (i=0, j=1; i <= NbEntities; ++i, j += nbEntityNodes)
    skyLineArrayIndex [ i ] = j;
  
  //  Connectivity->_nodal->setMEDSKYLINEARRAY (NbEntities, NbNodes,
  //skyLineArrayIndex, NodeNumbers);

  Connectivity->_nodal = new MEDSKYLINEARRAY (NbEntities, NbNodes,
					       skyLineArrayIndex, NodeNumbers);

  delete [] skyLineArrayIndex;

  // test connectivity right away
//   for (med_int j = 0; j < numberOfGeometricType; j++)
//   {
//     int node_number = Connectivity->_type[j].getNumberOfNodes();
//     for (med_int k = Connectivity->_count[j]; k < Connectivity->_count[j+1]; k++)
//       for (med_int local_node_number = 1 ; local_node_number < node_number+1; local_node_number++)
//       {
//         cout << "MEDSKYLINEARRAY::getIJ(" << k << ", " << local_node_number << endl;
//         med_int global_node = Connectivity->_nodal->getIJ(k,local_node_number) ;
//         cout << "...= " << global_node << endl;
//       }
//   }
  
  return Connectivity;
}

//=======================================================================
//function : fillConnectivity
//purpose  : fill _coordinates and _connectivity of MESH if not yet done
//=======================================================================

void GRID::fillConnectivity()
{
  if (_is_connectivity_filled)
  {
    MESSAGE("GRID::fillConnectivity(): Already filled");
    return;
  }

  const char * LOC = "GRID::fillConnectivity() ";
  BEGIN_OF(LOC);
  
  int nbCells, nbFaces, nbEdges;
  int nbCNodes, nbFNodes, nbENodes;
  int indexC, indexF, indexE;
  int * nodeCNumbers, * nodeFNumbers, * nodeENumbers;
  // about descending connectivity
  int nbSub, nbRevSub, indexSub, indexRevSub, * subNumbers, * subRevNumbers;

  bool hasFaces = _kArrayLength, hasEdges = _jArrayLength;
  
  int iLenMin1 = _iArrayLength-1, jLenMin1 = _jArrayLength-1;
  int kLenMin1 = _kArrayLength-1, ijLenMin1 = iLenMin1 * jLenMin1;
  if (!hasEdges) jLenMin1 = 1;
  if (!hasFaces) kLenMin1 = 1;

  // nb of cells and of their connectivity nodes

  nbCells = iLenMin1 * jLenMin1 * kLenMin1;
  nbCNodes = nbCells * 2 * (hasEdges ? 2 : 1) * (hasFaces ? 2 : 1);
  nodeCNumbers = new int [ nbCNodes ];

  // nb of faces and of their connectivity nodes

  if (hasFaces) {
    nbFaces  = _iArrayLength * jLenMin1 * kLenMin1;
    nbFaces += _jArrayLength * kLenMin1 * iLenMin1;
    nbFaces += _kArrayLength * iLenMin1 * jLenMin1;
    nbFNodes = nbFaces * 4;
    nodeFNumbers = new int [ nbFNodes ];
  } else
    nbFaces = nbFNodes = 0;

  // nb of edges and of their connectivity nodes

  if (hasEdges) {
    if (_kArrayLength) { // 3d grid
      nbEdges  = iLenMin1 * _jArrayLength * _kArrayLength;
      nbEdges += jLenMin1 * _kArrayLength * _iArrayLength;
      nbEdges += kLenMin1 * _iArrayLength * _jArrayLength;
    }
    else if (_jArrayLength) { // 2d
      nbEdges  = iLenMin1 * _jArrayLength;
      nbEdges += jLenMin1 * _iArrayLength;
    }
    nbENodes = nbEdges * 2;
    nodeENumbers = new int [ nbENodes ];
  } else
    nbEdges = nbENodes = 0;

  // nb of descending connectivity Elements
  
  if (hasFaces)
  {
    nbSub = nbCells * 6;
    nbRevSub = nbFaces * 2;
  }
  else
  {
    nbSub = nbCells * 4;
    nbRevSub = nbEdges * 2;
  }
  subNumbers = new int [ nbSub ];
  subRevNumbers = new int [ nbRevSub ];
  for (int r=0; r<nbRevSub; ++r)
    subRevNumbers[ r ] = 0;

  int nSubI = 1, nSubJ, nSubK; // subelement numbers
  if (hasFaces)
  {
    nSubJ = getFaceNumber(2, 0, 0, 0);
    nSubK = getFaceNumber(3, 0, 0, 0);
  }
  else
    nSubJ = getEdgeNumber(2, 0, 0, 0);
  

  // fill cell node numbers and descending element numbers


  indexC = indexF = indexE = indexSub = indexRevSub = -1;
  int iNode = 0, iCell = 0;
  int ijLen = _iArrayLength * _jArrayLength;
  int i, j, k, n1, n2, n3 ,n4;
  
  int I = _iArrayLength;
  int J = _jArrayLength ? _jArrayLength : 2; // pass at least once
  int K = _kArrayLength ? _kArrayLength : 2;
  // pass by all but last nodes in all directions
  for (k = 1; k < K; ++k ) {
    for (j = 1; j < J; ++j ) {
      for (i = 1; i < I; ++i ) {

        ++iCell;
        
        n1 = ++iNode; // iNode
        n2 = n1 + 1;
        nodeCNumbers [ ++indexC ] = n1;
        nodeCNumbers [ ++indexC ] = n2;

        if (hasEdges) { // at least 2d
          n3 = n2 + I;
          n4 = n3 - 1;
          nodeCNumbers [ ++indexC ] = n3;
          nodeCNumbers [ ++indexC ] = n4;
        }
        if (hasFaces) { // 3d
          nodeCNumbers [ ++indexC ] = n1 + ijLen;
          nodeCNumbers [ ++indexC ] = n2 + ijLen;
          nodeCNumbers [ ++indexC ] = n3 + ijLen;
          nodeCNumbers [ ++indexC ] = n4 + ijLen;

          // descending faces
          n1 = nSubI;
          n2 = n1 + 1;
          n3 = (n1-1) * 2;
          n4 = (n2-1) * 2 + 1;
          subNumbers [ ++indexSub ] = n1;
          subRevNumbers[ n3 ] = iCell;
          subNumbers [ ++indexSub ] = n2;
          subRevNumbers[ n4 ] = -iCell;
          n1 = nSubJ;
          n2 = n1 + iLenMin1;
          n3 = (n1-1) * 2;
          n4 = (n2-1) * 2 + 1;
          subNumbers [ ++indexSub ] = n1;
          subRevNumbers[ n3 ] = iCell;
          subNumbers [ ++indexSub ] = n2;
          subRevNumbers[ n4 ] = -iCell;
          n1 = nSubK;
          n2 = n1 + ijLenMin1;
          n3 = (n1-1) * 2;
          n4 = (n2-1) * 2 + 1;
          subNumbers [ ++indexSub ] = n1;
          subRevNumbers[ n3 ] = iCell;
          subNumbers [ ++indexSub ] = n2;
          subRevNumbers[ n4 ] = -iCell;
        }
        else
        {
          // descending edges
          n1 = nSubI;
          n2 = n1 + iLenMin1;
          n3 = (n1-1) * 2;
          n4 = (n2-1) * 2 + 1;
          subNumbers [ ++indexSub ] = n1;
          subRevNumbers[ n3 ] = iCell;
          subNumbers [ ++indexSub ] = n2;
          subRevNumbers[ n4 ] = -iCell;
          n1 = nSubJ;
          n2 = n1 + 1;
          n3 = (n1-1) * 2;
          n4 = (n2-1) * 2 + 1;
          subNumbers [ ++indexSub ] = n1;
          subRevNumbers[ n3 ] = iCell;
          subNumbers [ ++indexSub ] = n2;
          subRevNumbers[ n4 ] = -iCell;
        }
        ++nSubI; ++nSubJ; ++nSubK;
      }
      ++iNode; // skip the last node in a row
      if (hasFaces)
        ++nSubI;
      else
        ++nSubJ;
    }
    iNode += I; // skip the whole last row
  }

  // fill face node numbers

  int ax, AX = hasFaces ? 3 : 0;
  for (ax = 1; ax <= AX; ++ax) {

    iNode = 0;
    
    I = _iArrayLength;
    J = _jArrayLength;
    K = _kArrayLength;
    switch (ax) {
    case 1:  --J; --K; break;
    case 2:  --K; --I; break;
    default: --I; --J;
    }
    for (k = 1; k <= K; ++k ) {
      for (j = 1; j <= J; ++j ) {
        for (i = 1; i <= I; ++i ) {

          n1 = ++iNode;

          switch (ax) {
          case 1: // nodes for faces normal to i direction
            n2 = n1 + ijLen;
            n3 = n2 + I;
            n4 = n1 + I;
            break;
          case 2: // nodes for faces normal to j direction
            n2 = n1 + 1;
            n3 = n2 + ijLen;
            n4 = n3 - 1;
            break;
          default: // nodes for faces normal to k direction
            n2 = n1 + I;
            n3 = n2 + 1;
            n4 = n1 + 1;
          }
          nodeFNumbers [ ++indexF ] = n1;
          nodeFNumbers [ ++indexF ] = n2;
          nodeFNumbers [ ++indexF ] = n3;
          nodeFNumbers [ ++indexF ] = n4;
        }
        if (ax != 1) ++iNode;
      }
      if (ax != 2) iNode += _iArrayLength;
    }
  }
  if (nbFNodes != indexF+1) {
    throw MEDEXCEPTION(LOCALIZED(STRING(LOC) << "Wrong nbFNodes : " \
                                        << nbFNodes << " indexF : " << indexF ));
  }

  // fill edge node numbers

  AX = hasEdges ? _spaceDimension : 0;
  for (ax = 1; ax <= AX; ++ax) {

    iNode = 0;
    
    I = _iArrayLength;
    J = _jArrayLength;
    K = _kArrayLength;
    if (K == 0) K = 1;
    
    switch (ax) {
    case 1:  --I; break;
    case 2:  --J; break;
    default: --K;
    }
    for (k = 1; k <= K; ++k ) {
      for (j = 1; j <= J; ++j ) {
        for (i = 1; i <= I; ++i ) {

          n1 = ++iNode;

          switch (ax) {
          case 1: // nodes for edges going along i direction
            n2 = n1 + 1;
            break;
          case 2: // nodes for edges going along j direction
            n2 = n1 + _iArrayLength;
            break;
          default: // nodes for edges going along k direction
            n2 = n1 + ijLen;
          }
          nodeENumbers [ ++indexE ] = n1;
          nodeENumbers [ ++indexE ] = n2;
        }
        if (ax == 1) ++iNode;
      }
      if (ax == 2) iNode += _iArrayLength;
    }
  }
  if (nbENodes != indexE+1) {
    throw MEDEXCEPTION(LOCALIZED(STRING(LOC) << "Wrong nbFNodes : " \
                                        << nbENodes << " indexE : " << indexE ));
  }

  
  CONNECTIVITY * CellCNCT, * FaceCNCT, * EdgeCNCT;

  // make connectivity for CELL
  
  medGeometryElement aCellGeometry;
  if (_kArrayLength)      aCellGeometry = MED_HEXA8;
  else if (_jArrayLength) aCellGeometry = MED_QUAD4;
  else                    aCellGeometry = MED_SEG2;

  // nodal
  CellCNCT = makeConnectivity (MED_CELL, aCellGeometry, nbCells, nbCNodes, nodeCNumbers);

  delete [] nodeCNumbers;

  // descending
  {
    //    CellCNCT->_descending = new MEDSKYLINEARRAY() ;
    int * skyLineArrayIndex = new int [nbCells + 1];
    int nbEntitySub = CellCNCT->_type[0].getNumberOfConstituents(1);
    for (i=0, j=1; i <= nbCells; ++i, j += nbEntitySub)
      skyLineArrayIndex [ i ] = j;
    //    CellCNCT->_descending->setMEDSKYLINEARRAY (nbCells, nbSub,
    //                                               skyLineArrayIndex, subNumbers);
    CellCNCT->_descending = new MEDSKYLINEARRAY (nbCells, nbSub,
						 skyLineArrayIndex,
						 subNumbers);
    delete [] skyLineArrayIndex;
  }
  delete [] subNumbers;

  // reverse descending
  {
    //    CellCNCT->_reverseDescendingConnectivity = new MEDSKYLINEARRAY() ;
    nbSub = nbRevSub/2;
    int * skyLineArrayIndex = new int [nbSub + 1];
    for (i=0, j=1; i <= nbSub; ++i, j += 2)
      skyLineArrayIndex [ i ] = j;
    //    CellCNCT->_reverseDescendingConnectivity->setMEDSKYLINEARRAY
    //      (nbSub, nbRevSub, skyLineArrayIndex, subRevNumbers);

    CellCNCT->_reverseDescendingConnectivity =
      new MEDSKYLINEARRAY(nbSub, nbRevSub, skyLineArrayIndex, subRevNumbers);

    delete [] skyLineArrayIndex;
  }
  delete [] subRevNumbers;
  
  // make connectivity for FACE and/or EDGE
  
  if (hasFaces) {
    FaceCNCT = makeConnectivity (MED_FACE, MED_QUAD4, nbFaces, nbFNodes, nodeFNumbers);

    delete [] nodeFNumbers;

    CellCNCT->_constituent = FaceCNCT;
  }
  if (hasEdges) {
    EdgeCNCT = makeConnectivity (MED_EDGE, MED_SEG2, nbEdges, nbENodes, nodeENumbers);

    delete [] nodeENumbers;

    if (hasFaces)
      FaceCNCT->_constituent = EdgeCNCT;
    else
      CellCNCT->_constituent = EdgeCNCT;
  }

  MESH::_connectivity  = CellCNCT;

  _is_connectivity_filled = true;

  END_OF(LOC);
}

//=======================================================================
//function : getArrayLength
//purpose  : return array length. Axis = [1,2,3] meaning [i,j,k],
//=======================================================================

int GRID::getArrayLength( const int Axis ) throw (MEDEXCEPTION)
{
  switch (Axis) {
  case 1: return _iArrayLength;
  case 2: return _jArrayLength;
  case 3: return _kArrayLength;
  default:
    throw MED_EXCEPTION ( LOCALIZED( STRING("GRID::getArrayLength ( ") << Axis << ")"));
  }
  return 0;
}

//=======================================================================
//function : getArrayValue
//purpose  : return i-th array component. Axis = [1,2,3] meaning [i,j,k],
//           exception if Axis out of [1-3] range
//           exception if i is out of range 0 <= i < getArrayLength(Axis);
//=======================================================================

const double GRID::getArrayValue (const int Axis, const int i)
     throw (MEDEXCEPTION)
{
  if (i < 0 || i >= getArrayLength(Axis))
    throw MED_EXCEPTION
      ( LOCALIZED(STRING("GRID::getArrayValue ( ") << Axis << ", " << i << ")"));
  
  switch (Axis) {
  case 1:  return _iArray[ i ];
  case 2:  return _jArray[ i ];
  default: return _kArray[ i ];
  }
  return 0.0;
}

//=======================================================================
//function : getEdgeNumber
//purpose  : 
//=======================================================================

int GRID::getEdgeNumber(const int Axis, const int i, const int j, const int k)
     throw (MEDEXCEPTION)
{
  const char * LOC = "GRID::getEdgeNumber(Axis, i,j,k) :";

  int Len[4] = {0,_iArrayLength, _jArrayLength, _kArrayLength }, I=1, J=2, K=3;
  int maxAxis = Len[ K ] ? 3 : 2;
  
  if (Axis <= 0 || Axis > maxAxis)
    throw MED_EXCEPTION ( LOCALIZED(STRING(LOC) << "Axis out of range: " << Axis));

  Len[Axis]--;
  int Nb = 1 + i + j*Len[ I ] + k*Len[ J ]*Len[ K ];
  Len[Axis]++ ;
  
  if (!Len[ K ])
    Len[ K ] = 1; 

  if (Axis > 1) { // add all edges in i direction
    Len[I]-- ;
    Nb += Len[ I ]*Len[ J ]*Len[ K ];
    Len[I]++ ;
  }
  if (Axis > 2) { // add all edges in j direction
    Len[J]-- ;
    Nb += Len[ I ]*Len[ J ]*Len[ K ];
  }
  
  return Nb;
}

//=======================================================================
//function : getFaceNumber
//purpose  : return a NODE, EDGE, FACE, CELL number by its position in the grid.
//           Axis [1,2,3] means one of directions: along i, j or k
//           For Cell contituents (FACE or EDGE), Axis selects one of those having same (i,j,k):
//           * a FACE which is normal to direction along given Axis;
//           * an EDGE going along given Axis.
//           Exception for Axis out of range
//=======================================================================

int GRID::getFaceNumber(const int Axis, const int i, const int j, const int k)
     throw (MEDEXCEPTION)
{
  const char * LOC = "GRID::getFaceNumber(Axis, i,j,k) :";
  
//  if (Axis <= 0 || Axis > 3)
  if (Axis < 0 || Axis > 3)
    throw MED_EXCEPTION ( LOCALIZED(STRING(LOC) << "Axis = " << Axis));

  int Len[4] = {0,_iArrayLength-1, _jArrayLength-1, _kArrayLength-1 }, I=1, J=2, K=3;

  Len[Axis]++;
  int Nb = 1 + i + j*Len[ I ] + k*Len[ J ]*Len[ K ];
  Len[Axis]--;
  
  if (Axis > 1) { // add all faces in i direction
    Len[I]++ ;
    Nb += Len[ I ]*Len[ J ]*Len[ K ];
    Len[I]-- ;
  }
  if (Axis > 2) { // add all faces in j direction
    Len[J]++ ;
    Nb += Len[ I ]*Len[ J ]*Len[ K ];
  }
  
  return Nb;
}

//=======================================================================
//function : getNodePosition
//purpose  : 
//=======================================================================

void GRID::getNodePosition(const int Number, int& i, int& j, int& k)
     throw (MEDEXCEPTION)
{
  const char * LOC = "GRID::getNodePosition(Number, i,j,k) :";
  
  if (Number <= 0 || Number > _numberOfNodes)
    throw MED_EXCEPTION ( LOCALIZED(STRING(LOC) << "Number is out of range: " << Number));

  int Len[] = {_iArrayLength, _jArrayLength, _kArrayLength }, I=0, J=1, K=2;

  int ijLen = Len[I] * Len[J]; // nb in a full k layer
  int kLen = (Number - 1) % ijLen;    // nb in the non full k layer
  
  i = kLen % Len[J];
  j = kLen / Len[J];
  k = (Number - 1) / ijLen;

  ////cout <<" NODE POS: " << Number << " - " << i << ", " << j << ", " << k << endl;
}

//=======================================================================
//function : getCellPosition
//purpose  : 
//=======================================================================

void GRID::getCellPosition(const int Number, int& i, int& j, int& k)
     throw (MEDEXCEPTION)
{
  const char * LOC = "GRID::getCellPosition(Number, i,j,k) :";
  
  int Len[4] = {0,_iArrayLength-1, _jArrayLength-1, _kArrayLength-1 }, I=1, J=2, K=3;

//  if (Number <= 0 || Number > getCellNumber(Len[I]-1, Len[J]-1, Len[K]-1))
//    throw MED_EXCEPTION ( LOCALIZED(STRING(LOC) << "Number is out of range: " << Number));

  int ijLen = Len[I] * Len[J]; // nb in a full k layer
  int kLen = (Number - 1) % ijLen;    // nb in the non full k layer
  
  i = kLen % Len[J];
  j = kLen / Len[J];
  k = (Number - 1) / ijLen;
}

//=======================================================================
//function : getEdgePosition
//purpose  : 
//=======================================================================

void GRID::getEdgePosition(const int Number, int& Axis, int& i, int& j, int& k)
     throw (MEDEXCEPTION)
{
  const char * LOC = "GRID::getEdgePosition(Number, i,j,k) :";

  if (!_jArrayLength)
    throw MED_EXCEPTION ( LOCALIZED(STRING(LOC) << "no edges in the grid: "));
  
  if (Number <= 0)
    throw MED_EXCEPTION ( LOCALIZED(STRING(LOC) << "Number is out of range: " << Number));

  int Len[4] = {0,_iArrayLength, _jArrayLength, _kArrayLength }, I=1, J=2, K=3;

  int theNb = Number;
  int maxAxis = _kArrayLength ? 3 : 2;
  
  for (Axis = 1; Axis <= maxAxis; ++Axis)
  {
    Len[Axis]--;  // one less edge in Axis direction

    // max edge number in Axis direction
    int maxNb = getEdgeNumber (Axis, Len[I]-1, Len[J]-1, Len[K]-1);
    
    if (theNb > maxNb)
    {
      Len[Axis]++;
      theNb -= maxNb;
      continue;
    }
    
    if (theNb == maxNb)
    {
      i = Len[I]-1;
      j = Len[J]-1;
      k = Len[K]-1;
    }
    else
    {
      int ijLen = Len[I] * Len[J]; // nb in a full k layer
      int kLen = (theNb - 1) % ijLen;    // nb in the non full k layer
      i = kLen % Len[J];
      j = kLen / Len[J];
      k = (theNb - 1) / ijLen;
    }
    return;
  }
  
  throw MED_EXCEPTION ( LOCALIZED(STRING(LOC) << "Number is out of range: " << Number));
}

//=======================================================================
//function : getFacePosition
//purpose  : return position (i,j,k) of an entity #Number
//           Axis [1,2,3] means one of directions: along i, j or k
//           For Cell contituents (FACE or EDGE), Axis selects one of those having same (i,j,k):
//           * a FACE which is normal to direction along given Axis;
//           * an EDGE going along given Axis.
//           Exception for Number out of range
//=======================================================================

void GRID::getFacePosition(const int Number, int& Axis, int& i, int& j, int& k)
     throw (MEDEXCEPTION)
{
  const char * LOC = "GRID::getFacePosition(Number, i,j,k) :";

     if (_kArrayLength == 0) {
         getCellPosition(Number, i, j, k);
         Axis = 1;
         return;
     };

  if (!_kArrayLength)
    throw MED_EXCEPTION ( LOCALIZED(STRING(LOC) << "no faces in the grid: "));
  
  if ( Number <= 0 )
    throw MED_EXCEPTION ( LOCALIZED(STRING(LOC) << "Number is out of range: " << Number));

  int Len[4] = {0,_iArrayLength-1, _jArrayLength-1, _kArrayLength-1 }, I=1, J=2, K=3;
  int theNb = Number;
  
  for (Axis = 1; Axis <= 3; ++Axis)
  {
    Len[Axis]++;

    // max face number in Axis direction
    int maxNb = getFaceNumber (Axis, Len[I]-1, Len[J]-1, Len[K]-1);
    
    if (theNb > maxNb)
    {
      Len[Axis]--;
      theNb -= maxNb;
      continue;
    }
    
    if (theNb == maxNb)
    {
      i = Len[I]-1;
      j = Len[J]-1;
      k = Len[K]-1;
    }
    else
    {
      int ijLen = Len[I] * Len[J]; // nb in a full k layer
      int kLen = (theNb - 1)  % ijLen;    // nb in the non full k layer
      i = kLen % Len[J];
      j = kLen / Len[J];
      k = (theNb - 1) / ijLen;
    }
    return;
  }
  
  throw MED_EXCEPTION ( LOCALIZED(STRING(LOC) << "Number is out of range: " << Number));
}

//=======================================================================
//function : writeUnstructured
//purpose  : write a Grid as an Unstructured mesh
//=======================================================================

void GRID::writeUnstructured(int index, const string & driverName)
{
  const char * LOC = "GRID::writeUnstructured(int index=0, const string & driverName) : ";
  BEGIN_OF(LOC);

  if ( _drivers[index] ) {

    makeUnstructured();
    _isAGrid = false;
    
    _drivers[index]->open();   
    if (driverName != "") _drivers[index]->setMeshName(driverName); 
    _drivers[index]->write(); 
    _drivers[index]->close(); 

    _isAGrid = true;
  }
  else
    throw MED_EXCEPTION ( LOCALIZED( STRING(LOC) 
                                    << "The index given is invalid, index must be between  0 and |" 
                                    << _drivers.size() 
                                    )
                         ); 
  END_OF(LOC);
}