import Base: ==, !=, hash, isequal, length

immutable PDBResidueIdentifier
	number::ASCIIString
	name::ASCIIString
	group::ASCIIString
	model::ASCIIString
	chain::ASCIIString
end

hash(a::PDBResidueIdentifier) = hash(string(a.number, a.name, a.group, a.model,a.chain))

isequal(a::PDBResidueIdentifier, b::PDBResidueIdentifier) = hash(a) == hash(b)

function ==(a::PDBResidueIdentifier, b::PDBResidueIdentifier)
  a.number == b.number && a.name == b.name && a.group == b.group && a.chain == b.chain && a.model == b.model
end

function !=(a::PDBResidueIdentifier, b::PDBResidueIdentifier)
  a.number != b.number && a.name != b.name && a.group != b.group && a.chain != b.chain && a.model != b.model
end

immutable Coordinates{T<:FloatingPoint}
  x::T
  y::T
  z::T
end

distance(a::Coordinates, b::Coordinates) = sqrt((a.x - b.x)^2 + (a.y - b.y)^2 + (a.z - b.z)^2)

contact(a::Coordinates, b::Coordinates, limit::FloatingPoint) = distance(a,b) <= limit ? true : false

immutable PDBAtom{T<:FloatingPoint}
  residueid::PDBResidueIdentifier
  coordinates::Coordinates{T}
  atomid::ASCIIString
  element::ASCIIString
  occupancy::T
  B::ASCIIString
end

distance(a::PDBAtom, b::PDBAtom) = distance(a.coordinates, b.coordinates)

contact(a::PDBAtom, b::PDBAtom, limit::FloatingPoint) = contact(a.coordinates, b.coordinates, limit)

type PDBResidue{T<:FloatingPoint}
  id::PDBResidueIdentifier
	atoms::Vector{PDBAtom{T}}
end

length(res::PDBResidue) = length(res.atoms)

function findheavy(res::PDBResidue)
  N = length(res)
  indices = Array(Int,N)
  j = 0
  @inbounds for i in 1:N
    if res.atoms[i].element != "H"
      j += 1
      indices[j] = i
    end
  end
  resize!(indices, j)
end

function findCA(res::PDBResidue)
  N = length(res)
  indices = Array(Int,N)
  j = 0
  @inbounds for i in 1:N
    if res.atoms[i].atomid == "CA"
      j += 1
      indices[j] = i
    end
  end
  resize!(indices, j)
end

function findCB(res::PDBResidue)
  N = length(res)
  indices = Array(Int,N)
  j = 0
  @inbounds for i in 1:N
    if (res.atoms[i].residueid.name == "GLY" && res.atoms[i].atomid == "CA") || res.atoms[i].atomid == "CB"
      j += 1
      indices[j] = i
    end
  end
  resize!(indices, j)
end

function selectbestoccupancy(res::PDBResidue, indices::Vector{Int})
  Ni = length(indices)
  if Ni == 1
    return(indices[1])
  end
  Na = length(res)
  if Ni == 0 || Ni > Na
    throw("There are not atom indices or they are more atom indices than atoms in the Residue")
  end
  indice = 1
  occupancy = 0.0
  for i in indices
    actual_occupancy = res.atoms[i].occupancy
    if actual_occupancy > occupancy
      occupancy = actual_occupancy
      indice = i
    end
  end
  return(indice)
end

function __update_distance(a, b, i, j, dist)
  actual_dist = distance(a.atoms[i], b.atoms[j])
  if actual_dist < dist
    return(actual_dist)
  else
    return(dist)
  end
end

"""Heavy, All, CA, CB (CA for GLY)"""
function distance(a::PDBResidue, b::PDBResidue; criteria::ASCIIString="All")
  dist = Inf
  if criteria == "All"
    Na = length(a)
    Nb = length(b)
    @inbounds for i in 1:Na
      for j in 1:Nb
        dist = __update_distance(a, b, i, j, dist)
      end
    end
  elseif criteria == "Heavy"
    indices_a = findheavy(a)
    indices_b = findheavy(b)
    if length(indices_a) != 0 && length(indices_b) != 0
      for i in indices_a
        for j in indices_b
          dist = __update_distance(a, b, i, j, dist)
        end
      end
    end
  elseif criteria == "CA"
    indices_a = findCA(a)
    indices_b = findCA(b)
    if length(indices_a) != 0 && length(indices_b) != 0
      for i in indices_a
        for j in indices_b
          dist = __update_distance(a, b, i, j, dist)
        end
      end
    end
  elseif criteria == "CB"
    indices_a = findCB(a)
    indices_b = findCB(b)
    if length(indices_a) != 0 && length(indices_b) != 0
      for i in indices_a
        for j in indices_b
          dist = __update_distance(a, b, i, j, dist)
        end
      end
    end
  end
  dist
end

"""Heavy, All, CA, CB (CA for GLY)"""
function contact(a::PDBResidue, b::PDBResidue, limit::FloatingPoint; criteria::ASCIIString="All")
  if criteria == "All"
    Na = length(a)
    Nb = length(b)
    @inbounds for i in 1:Na
      for j in 1:Nb
        if contact(a.atoms[i], b.atoms[j], limit)
          return(true)
        end
      end
    end
  elseif criteria == "Heavy"
    indices_a = findheavy(a)
    indices_b = findheavy(b)
    if length(indices_a) != 0 && length(indices_b) != 0
      for i in indices_a
        for j in indices_b
          if contact(a.atoms[i], b.atoms[j], limit)
            return(true)
          end
        end
      end
    end
  elseif criteria == "CA"
    indices_a = findCA(a)
    indices_b = findCA(b)
    if length(indices_a) != 0 && length(indices_b) != 0
      for i in indices_a
        for j in indices_b
          if contact(a.atoms[i], b.atoms[j], limit)
            return(true)
          end
        end
      end
    end
  elseif criteria == "CB"
    indices_a = findCB(a)
    indices_b = findCB(b)
    if length(indices_a) != 0 && length(indices_b) != 0
      for i in indices_a
        for j in indices_b
          if contact(a.atoms[i], b.atoms[j], limit)
            return(true)
          end
        end
      end
    end
  end
  false
end
