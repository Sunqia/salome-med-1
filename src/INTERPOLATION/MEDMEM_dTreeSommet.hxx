#ifndef SOMMET_HPP
#define SOMMET_HPP


// La classe qui suit sert UNIQUEMENT pour les sommets du dTree

template <int DIMENSION> class Sommet_dTree
{
protected :
	double coord[DIMENSION];
public :
	Sommet_dTree() 
		{
		}
	Sommet_dTree(double *c) 
		{
		for (int i=0;i<DIMENSION;i++) coord[i]=c[i];
		}
	Sommet_dTree(double c)
		{
		for (int i=0;i<DIMENSION;i++) coord[i]=c;
		}
	Sommet_dTree(const Sommet_dTree & SO) 
		{
		for (int i=0;i<DIMENSION;i++) coord[i]=SO.coord[i];
		}
	Sommet_dTree(const Sommet_dTree &s1,const Sommet_dTree &s2) 
		{
		for (int i=0;i<DIMENSION;i++) coord[i]=0.5*(s1[i]+s2[i]);
		}
	~Sommet_dTree() 
		{
		}
	const double operator[](int i) const 
		{
		return coord[i];
		}
	double & operator[](int i) 
		{
		return coord[i];
		}
	Sommet_dTree & operator=(const Sommet_dTree &f) 
		{
		for (int i=0;i<DIMENSION;i++) coord[i]=f.coord[i];return *this;
		}
	friend double DistanceInf(const Sommet_dTree<DIMENSION> &A,const Sommet_dTree<DIMENSION> &B) 
		{
		double max=0;
		double tmp;
		for (int i=0;i<DIMENSION;i++)
			{
			tmp=fabs(A[i]-B[i]);
			if (tmp>max) max=tmp;
			}
		return max;
		}
};

#endif