# import Base: length, getindex, setindex!, size, copy, deepcopy, empty!,
#              convert, transpose, names

"""
MIToS MSA and aligned sequences (aligned objects) are subtypes of `AbstractMatrix{Residue}`,
because MSAs and sequences are stored as `Matrix` of `Residue`s.
"""
abstract type AbstractAlignedObject <: AbstractMatrix{Residue} end

"""
MSAs are stored as `Matrix{Residue}`. It's possible to use a
`NamedResidueMatrix{Array{Residue,2}}` as the most simple MSA with sequence
identifiers and column names.
"""
abstract type AbstractMultipleSequenceAlignment <: AbstractAlignedObject end

"""
A MIToS aligned sequence is an `AbstractMatrix{Residue}` with only 1 row/sequence.
"""
abstract type AbstractAlignedSequence <: AbstractAlignedObject end

# Multiple Sequence Alignment
# ===========================

const NamedResidueMatrix{AT} =
    NamedArray{Residue,2,AT,Tuple{OrderedDict{String,Int},OrderedDict{String,Int}}}

"""
This MSA type include a `NamedArray` wrapping a `Matrix` of `Residue`s. The use of
`NamedArray` allows to store sequence names and original column numbers as `String`s, and
fast indexing using them.
"""
mutable struct MultipleSequenceAlignment <: AbstractMultipleSequenceAlignment
    matrix::NamedResidueMatrix{Array{Residue,2}}

    function (::Type{MultipleSequenceAlignment})(
        matrix::NamedResidueMatrix{Array{Residue,2}},
    )
        setdimnames!(matrix, ("Seq", "Col"))
        new(matrix)
    end
end

"""
This type represent an MSA, similar to `MultipleSequenceAlignment`, but It also stores
`Annotations`. This annotations are used to store residue coordinates (i.e. mapping
to UniProt residue numbers).
"""
mutable struct AnnotatedMultipleSequenceAlignment <: AbstractMultipleSequenceAlignment
    matrix::NamedArray{
        Residue,
        2,
        Array{Residue,2},
        Tuple{OrderedDict{String,Int},OrderedDict{String,Int}},
    }
    annotations::Annotations

    function (::Type{AnnotatedMultipleSequenceAlignment})(
        matrix::NamedResidueMatrix{Array{Residue,2}},
        annotations::Annotations,
    )
        setdimnames!(matrix, ("Seq", "Col"))
        new(matrix, annotations)
    end
end

# Helper constructor for NamedResidueMatrix{Array{Residue,2}}
function _namedresiduematrix(
    matrix::Matrix{Residue},
    seqnames::OrderedDict{String,Int},
    colnames::OrderedDict{String,Int},
)::NamedResidueMatrix{Array{Residue,2}}
    NamedArray(matrix, (seqnames, colnames), ("Seq", "Col"))
end

function _namedresiduematrix(matrix::Matrix{Residue}, seqnames, colnames)
    _namedresiduematrix(
        matrix,
        OrderedDict{String,Int}(string(k) => i for (i, k) in enumerate(seqnames)),
        OrderedDict{String,Int}(string(k) => i for (i, k) in enumerate(colnames)),
    )
end

# Aligned Sequences
# -----------------

"""
An `AlignedSequence` wraps a `NamedResidueMatrix{Array{Residue,2}}` with only 1 row/sequence. The
`NamedArray` stores the sequence name and original column numbers as `String`s.
"""
mutable struct AlignedSequence <: AbstractAlignedSequence
    matrix::NamedResidueMatrix{Array{Residue,2}}

    function (::Type{AlignedSequence})(matrix::NamedResidueMatrix{Array{Residue,2}})
        @assert size(matrix, 1) == 1 "There are more than one sequence."
        setdimnames!(matrix, ("Seq", "Col"))
        new(matrix)
    end
end

"""
This type represent an aligned sequence, similar to `AlignedSequence`, but It also stores
its `Annotations`.
"""
mutable struct AnnotatedAlignedSequence <: AbstractAlignedSequence
    matrix::NamedResidueMatrix{Array{Residue,2}}
    annotations::Annotations

    function (::Type{AnnotatedAlignedSequence})(
        matrix::NamedResidueMatrix{Array{Residue,2}},
        annotations::Annotations,
    )
        @assert size(matrix, 1) == 1 "There are more than one sequence."
        setdimnames!(matrix, ("Seq", "Col"))
        new(matrix, annotations)
    end
end

# Constructors
# ------------

# AnnotatedMultipleSequenceAlignment

function AnnotatedMultipleSequenceAlignment(msa::NamedResidueMatrix{Array{Residue,2}})
    AnnotatedMultipleSequenceAlignment(msa, Annotations())
end

function AnnotatedMultipleSequenceAlignment(msa::Matrix{Residue})
    AnnotatedMultipleSequenceAlignment(NamedArray(msa))
end

function AnnotatedMultipleSequenceAlignment(msa::AbstractMatrix{Residue})
    AnnotatedMultipleSequenceAlignment(Matrix{Residue}(msa))
end

function AnnotatedMultipleSequenceAlignment(msa::MultipleSequenceAlignment)
    AnnotatedMultipleSequenceAlignment(namedmatrix(msa), Annotations())
end

AnnotatedMultipleSequenceAlignment(msa::AnnotatedMultipleSequenceAlignment) = msa

# MultipleSequenceAlignment

function MultipleSequenceAlignment(msa::Matrix{Residue})
    MultipleSequenceAlignment(NamedArray(msa))
end

function MultipleSequenceAlignment(msa::AbstractMatrix{Residue})
    MultipleSequenceAlignment(Matrix{Residue}(msa))
end

function MultipleSequenceAlignment(msa::AnnotatedMultipleSequenceAlignment)
    MultipleSequenceAlignment(namedmatrix(msa))
end

MultipleSequenceAlignment(msa::MultipleSequenceAlignment) = msa

# AnnotatedAlignedSequence

function AnnotatedAlignedSequence(seq::NamedResidueMatrix{Array{Residue,2}})
    AnnotatedAlignedSequence(seq, Annotations())
end

function AnnotatedAlignedSequence(seq::Matrix{Residue})
    AnnotatedAlignedSequence(NamedArray(seq))
end

function AnnotatedAlignedSequence(seq::AbstractMatrix{Residue})
    AnnotatedAlignedSequence(Matrix{Residue}(seq))
end

function AnnotatedAlignedSequence(seq::AlignedSequence)
    AnnotatedAlignedSequence(namedmatrix(seq), Annotations())
end

AnnotatedAlignedSequence(seq::AnnotatedAlignedSequence) = seq

# AlignedSequence

AlignedSequence(seq::Matrix{Residue}) = AlignedSequence(NamedArray(seq))

AlignedSequence(seq::AbstractMatrix{Residue}) = AlignedSequence(Matrix{Residue}(seq))

AlignedSequence(seq::AnnotatedAlignedSequence) = AlignedSequence(namedmatrix(seq))

AlignedSequence(seq::AlignedSequence) = seq

# AnnotatedAlignedObject
# ----------------------

const AnnotatedAlignedObject =
    Union{AnnotatedMultipleSequenceAlignment,AnnotatedAlignedSequence}

const UnannotatedAlignedObject = Union{MultipleSequenceAlignment,AlignedSequence}

# Matrices
# --------

const MSAMatrix = Union{Matrix{Residue},NamedResidueMatrix{Array{Residue,2}}}

# Getters
# -------

"""
The `annotations` function returns the `Annotations` of an annotated MSA or aligned
sequence. If the object is not annotated, it returns an empty `Annotations` object.
"""
@inline annotations(msa::AnnotatedMultipleSequenceAlignment) = msa.annotations
@inline annotations(seq::AnnotatedAlignedSequence) = seq.annotations
@inline annotations(x::UnannotatedAlignedObject) = Annotations()
@inline annotations(x::MSAMatrix) = Annotations()

"""
The `namedmatrix` function returns the `NamedResidueMatrix{Array{Residue,2}}` stored in an
MSA or aligned sequence.
"""
@inline namedmatrix(x::AbstractAlignedObject) = x.matrix

# Convert
# -------

function Base.convert(
    ::Type{MultipleSequenceAlignment},
    msa::AnnotatedMultipleSequenceAlignment,
)
    @warn "`convert(::Type{MultipleSequenceAlignment}, msa)` has been deprecated. Use `MultipleSequenceAlignment(msa)`"
    MultipleSequenceAlignment(namedmatrix(msa))
end

function Base.convert(::Type{AlignedSequence}, seq::AnnotatedAlignedSequence)
    @warn "`convert(::Type{AlignedSequence}, seq)` has been deprecated. Use `AlignedSequence(seq)`"
    AlignedSequence(namedmatrix(seq))
end

function Base.convert(
    ::Type{AnnotatedMultipleSequenceAlignment},
    msa::MultipleSequenceAlignment,
)
    @warn "`convert(::Type{AnnotatedMultipleSequenceAlignment}, msa)` has been deprecated. Use `AnnotatedMultipleSequenceAlignment(msa)`"
    AnnotatedMultipleSequenceAlignment(namedmatrix(msa), Annotations())
end

function Base.convert(::Type{AnnotatedAlignedSequence}, seq::AlignedSequence)
    @warn "`convert(::Type{AnnotatedAlignedSequence}, seq)` has been deprecated. Use `AnnotatedAlignedSequence(seq)`"
    AnnotatedAlignedSequence(namedmatrix(seq), Annotations())
end

# AbstractArray Interface
# -----------------------

for f in (:size, :length)
    @eval Base.$(f)(x::AbstractAlignedObject) = $(f)(namedmatrix(x))
end

# Show
# ----

for T in (
    :(AlignedSequence),
    :(AnnotatedAlignedSequence),
    :(MultipleSequenceAlignment),
    :(AnnotatedMultipleSequenceAlignment),
)
    @eval begin

        function Base.show(io::IO, ::MIME"text/plain", x::$(T))
            type_name = split(string($T), '.')[end]
            if isa(x, AnnotatedAlignedObject)
                print(io, type_name, " with ", length(annotations(x)), " annotations : ")
            else
                print(io, type_name, " : ")
            end
            show(io, MIME"text/plain"(), namedmatrix(x))
        end

    end
end

# Transpose (permutedims)
# -----------------------

function Base.transpose(x::AbstractAlignedObject)
    @warn "`transpose(x::AbstractAlignedObject)` has been deprecated, use `permutedims(x)` instead."
    permutedims(namedmatrix(x))
end

Base.permutedims(x::AbstractAlignedObject, args...) = permutedims(namedmatrix(x), args...)

# Selection without Mappings
# --------------------------

"""
`getresidues` allows you to access the residues stored inside an MSA or aligned sequence
as a `Matrix{Residue}` without annotations nor column/row names.
"""
getresidues(x::Matrix{Residue}) = x
getresidues(x::NamedResidueMatrix{Array{Residue,2}}) = getarray(x)
getresidues(x::AbstractAlignedObject) = getresidues(namedmatrix(x))

"""
`nsequences` returns the number of sequences on the MSA.
"""
nsequences(x::AbstractMatrix{Residue}) = size(x, 1)

"""
`ncolumns` returns the number of MSA columns or positions.
"""
ncolumns(x::AbstractMatrix{Residue}) = size(x, 2)

"""
`getresiduesequences` returns a `Vector{Vector{Residue}}` with all the MSA sequences without
annotations nor column/sequence names.
"""
function getresiduesequences(msa::Matrix{Residue})
    nseq = nsequences(msa)
    tmsa = permutedims(msa, [2, 1])
    sequences = Array{Vector{Residue}}(undef, nseq)
    for i = 1:nseq
        @inbounds sequences[i] = tmsa[:, i]
    end
    sequences
end

getresiduesequences(x::NamedResidueMatrix{Array{Residue,2}}) =
    getresiduesequences(getresidues(x))
getresiduesequences(x::AbstractAlignedObject) = getresiduesequences(getresidues(x))

# Select sequence
# ---------------

# Gives you the annotations of the Sequence
function getsequence(data::Annotations, id::String)
    GS = Dict{Tuple{String,String},String}()
    GR = Dict{Tuple{String,String},String}()
    if length(data.sequences) > 0
        for (key, value) in data.sequences
            if key[1] == id
                GS[key] = value
            end
        end
        sizehint!(GS, length(GS))
    end
    if length(data.residues) > 0
        for (key, value) in data.residues
            if key[1] == id
                GR[key] = value
            end
        end
        sizehint!(GR, length(GR))
    end
    Annotations(data.file, GS, data.columns, GR)
end

@doc """
`getsequence` takes an MSA and a sequence number or identifier and returns an aligned
sequence object. If the MSA is an `AnnotatedMultipleSequenceAlignment`, it returns an
`AnnotatedAlignedSequence` with the sequence annotations. From a
`MultipleSequenceAlignment`, It returns an `AlignedSequence` object. If an `Annotations`
object and a sequence identifier are used, this function returns the annotations related
to the sequence.
""" getsequence

getsequence(msa::AbstractMatrix{Residue}, i::Int) = msa[i:i, :]

getsequence(msa::NamedResidueMatrix{Array{Residue,2}}, i::Int) = msa[i:i, :]
getsequence(msa::NamedResidueMatrix{Array{Residue,2}}, id::String) = msa[String[id], :]

function getsequence(msa::AnnotatedMultipleSequenceAlignment, i::Int)
    seq = namedmatrix(msa)[i:i, :]
    annot = getsequence(annotations(msa), names(seq, 1)[1])
    AnnotatedAlignedSequence(seq, annot)
end

function getsequence(msa::AnnotatedMultipleSequenceAlignment, id::String)
    seq = namedmatrix(msa)[String[id], :]
    annot = getsequence(annotations(msa), id)
    AnnotatedAlignedSequence(seq, annot)
end

function getsequence(msa::MultipleSequenceAlignment, seq::String)
    AlignedSequence(getsequence(namedmatrix(msa), seq))
end

function getsequence(msa::MultipleSequenceAlignment, seq::Int)
    AlignedSequence(getsequence(namedmatrix(msa), seq))
end

# Names
# -----

"""
`sequencenames(msa)`

It returns a `Vector{String}` with the sequence names/identifiers.
"""
function sequencenames(x::NamedResidueMatrix{AT})::Vector{String} where {AT<:AbstractArray}
    names(x, 1)
end
sequencenames(x::AbstractAlignedObject)::Vector{String} = sequencenames(namedmatrix(x))
sequencenames(msa::AbstractMatrix{Residue})::Vector{String} = map(string, 1:size(msa, 1))

"""
`columnnames(msa)`

It returns a `Vector{String}` with the sequence names/identifiers. If the `msa` is a
`Matrix{Residue}` this function returns the actual column numbers as strings. Otherwise it
returns the column number of the original MSA through the wrapped `NamedArray` column names.
"""
function columnnames(x::NamedResidueMatrix{AT})::Vector{String} where {AT}
    names(x, 2)
end
columnnames(x::AbstractAlignedObject)::Vector{String} = columnnames(namedmatrix(x))
columnnames(msa::AbstractMatrix{Residue})::Vector{String} = map(string, 1:size(msa, 2))

# Name Iterators
# --------------
# These function relies on the internal implementation of NamedArrays
# to return the key iterator of the OrderedDict containing the row or column names.
# That should help reduce allocations in places where a vector of names is not needed.

"""
`sequencename_iterator(msa)`

It returns an iterator that returns the sequence names/identifiers of the `msa`.
"""
function sequencename_iterator(x::NamedResidueMatrix{AT}) where {AT}
    keys(x.dicts[1])::Base.KeySet{String,OrderedDict{String,Int64}}
end
sequencename_iterator(x::AbstractAlignedObject) = sequencename_iterator(namedmatrix(x))
sequencename_iterator(msa::AbstractMatrix{Residue}) = (string(i) for i = 1:size(msa, 1))

"""
`columnname_iterator(msa)`

It returns an iterator that returns the column names of the `msa`. If the `msa` is a
`Matrix{Residue}` this function returns the actual column numbers as strings. Otherwise it
returns the column number of the original MSA through the wrapped `NamedArray` column names.
"""
function columnname_iterator(x::NamedResidueMatrix{AT}) where {AT}
    keys(x.dicts[2])
end
columnname_iterator(x::AbstractAlignedObject) = columnname_iterator(namedmatrix(x))
columnname_iterator(msa::AbstractMatrix{Residue}) = (string(i) for i = 1:size(msa, 2))

# Copy, deepcopy
# --------------

for f in (:copy, :deepcopy)
    @eval begin
        function Base.$(f)(msa::AnnotatedMultipleSequenceAlignment)
            AnnotatedMultipleSequenceAlignment(
                $(f)(namedmatrix(msa)),
                $(f)(annotations(msa)),
            )
        end
        function Base.$(f)(msa::MultipleSequenceAlignment)
            MultipleSequenceAlignment($(f)(namedmatrix(msa)))
        end
        function Base.$(f)(seq::AnnotatedAlignedSequence)
            AnnotatedAlignedSequence($(f)(seq.matrix), $(f)(seq.annotations))
        end
        Base.$(f)(seq::AlignedSequence) = AlignedSequence($(f)(seq.matrix))
    end
end

# Get annotations
# ---------------

for getter in (:getannotcolumn, :getannotfile, :getannotresidue, :getannotsequence)
    @eval $(getter)(x::AnnotatedAlignedObject, args...) = $(getter)(annotations(x), args...)
end

# Set annotations
# ---------------

for setter in (
    :setannotcolumn!,
    :setannotfile!,
    :setannotresidue!,
    :setannotsequence!,
    :annotate_modification!,
    :delete_annotated_modifications!,
    :printmodifications,
)
    @eval $(setter)(x::AnnotatedAlignedObject, args...) = $(setter)(annotations(x), args...)
end

# To be used on AbstractMultipleSequenceAlignment methods
@inline function annotate_modification!(msa::MultipleSequenceAlignment, str::String)
    # It's generally used in a boolean context: annotate && annotate_modification!(...
    false
end

# Mapping annotations
# ===================

"""
Converts a string of mappings into a vector of `Int`s

```jldoctest
julia> using MIToS.MSA

julia> MSA._str2int_mapping(",,2,,4,5")
6-element Vector{Int64}:
 0
 0
 2
 0
 4
 5
```
"""
function _str2int_mapping(mapping::String)
    values = split(mapping, ',')
    len = length(values)
    intmap = Array{Int}(undef, len)
    @inbounds for i = 1:len
        value = values[i]
        intmap[i] = value == "" ? 0 : parse(Int, value)
    end
    intmap
end

"""
It returns a `Vector{Int}` with the original column number of each column on the actual MSA.
The mapping is annotated in the `ColMap` file annotation of an
`AnnotatedMultipleSequenceAlignment` or in the column names of an `NamedArray` or
`MultipleSequenceAlignment`.

NOTE: When the MSA results from vertically concatenating MSAs using `vcat`,
the column map annotations from the constituent MSAs (such as `1_ColMap`, `2_ColMap`, etc.)
are not returned. Instead, the column numbers referenced in the column names are provided.
To access the original annotations, utilize the `getannotfile` function.
"""
function getcolumnmapping(msa::AnnotatedMultipleSequenceAlignment)
    annot = getannotfile(msa)
    if haskey(annot, "ColMap")
        return _str2int_mapping(annot["ColMap"])
    else
        if haskey(annot, "1_ColMap")
            @warn """
            The MSA is the result of a vertical concatenation of MSAs. The column mapping 
            annotations from the sub-MSAs are not returned. Instead, the column numbers 
            referenced in the column names are provided. To access the original 
            annotations, utilize the getannotfile function. For example:
            `getannotfile(msa, "1_ColMap")`
            """
        end
        return getcolumnmapping(namedmatrix(msa))
    end
end

function getcolumnmapping(msa::NamedResidueMatrix{AT}) where {AT<:AbstractMatrix}
    # replace to clean names from hcat
    Int[parse(Int, replace(col, r"^[0-9]+_" => "")) for col in names(msa, 2)]
end

getcolumnmapping(msa::MultipleSequenceAlignment) = getcolumnmapping(namedmatrix(msa))

"""
It returns the sequence coordinates as a `Vector{Int}` for an MSA sequence. That vector has
one element for each MSA column. If the number if `0` in the mapping, there is a gap in
that column for that sequence.
"""
function getsequencemapping(msa::AnnotatedMultipleSequenceAlignment, seq_id::String)
    _str2int_mapping(getannotsequence(msa, seq_id, "SeqMap"))
end

function getsequencemapping(msa::AnnotatedMultipleSequenceAlignment, seq_num::Int)
    getsequencemapping(msa, sequencenames(msa)[seq_num])
end

# Sequences as strings
# --------------------

"""
```
stringsequence(seq)
stringsequence(msa, i::Int)
stringsequence(msa, id::String)
```

It returns the selected sequence as a `String`.
"""
stringsequence(msa::AbstractMatrix{Residue}, i) = String(vec(msa[i, :]))

function stringsequence(msa::AbstractMultipleSequenceAlignment, i)
    stringsequence(namedmatrix(msa), i)
end

function stringsequence(seq::AbstractMatrix{Residue})
    @assert size(seq, 1) == 1 "There are more than one sequence/row."
    String(vec(seq))
end

stringsequence(seq::AbstractAlignedSequence) = stringsequence(namedmatrix(seq))

# Rename sequences
# ----------------

const RENAME_SEQUENCES_DOC = md"""
Rename the sequences of an MSA given a vector of new names, a dictionary mapping old names 
to new names, or one or more pairs going from old to new names. If the `msa` is an 
`AnnotatedMultipleSequenceAlignment`, the annotations are also updated.
"""

"""
    rename_sequences!(msa, newnames)
    rename_sequences!(msa, old2new::AbstractDict)
    rename_sequences!(msa, old2new::Pair...)
    
$RENAME_SEQUENCES_DOC The function modifies the `msa` in place and returns it.
"""
function rename_sequences!(msa::NamedResidueMatrix{AT}, newnames) where {AT}
    setnames!(msa, newnames, 1)
    msa
end

function rename_sequences!(msa::MultipleSequenceAlignment, newnames)
    rename_sequences!(namedmatrix(msa), newnames)
    msa
end

function rename_sequences!(msa::AnnotatedMultipleSequenceAlignment, newnames)
    name_mapping = Dict{String,String}(
        old => new for
        (old, new) in zip(sequencename_iterator(msa), newnames) if old != new
    )
    new_annotations = _rename_sequences(annotations(msa), name_mapping)
    rename_sequences!(namedmatrix(msa), newnames)
    msa.annotations = new_annotations
    msa
end

"""
    rename_sequences(msa, newnames)
    rename_sequences(msa, old2new::AbstractDict)
    rename_sequences(msa, old2new::Pair...)

$RENAME_SEQUENCES_DOC The function returns a new MSA with the sequences renamed without 
modifying the original MSA.
"""
rename_sequences(msa, newnames) = rename_sequences!(deepcopy(msa), newnames)

# Rename a single sequence or a set of sequences

function _newnames(msa, old2new::AbstractDict)
    String[get(old2new, name, name) for name in sequencename_iterator(msa)]
end

_newnames(msa, old2new::Pair...) = _newnames(msa, Dict(old2new))

function rename_sequences!(msa, old2new::AbstractDict)
    rename_sequences!(msa, _newnames(msa, old2new))
end

function rename_sequences!(msa, old2new::Pair...)
    rename_sequences!(msa, _newnames(msa, old2new...))
end

rename_sequences(msa, old2new::Pair...) = rename_sequences(msa, _newnames(msa, old2new...))
