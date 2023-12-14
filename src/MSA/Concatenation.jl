## hcat (horizontal concatenation)

function _hcat_seqnames_kernel!(concatenated_names, msa, delim)
	for (i, seq) in enumerate(sequencename_iterator(msa))
		if seq == concatenated_names[i]
			continue
		end
		concatenated_names[i] *= delim * seq
	end
	concatenated_names
end

function _h_concatenated_seq_names(msas...; delim::String="_&_")
	concatenated_names = sequencenames(msas[1])
	for msa in msas[2:end]
		_hcat_seqnames_kernel!(concatenated_names, msa, delim)
	end
	concatenated_names
end

function _hcat_colnames_kernel!(colnames, columns, msa_number::Int)::Int
	first_col = first(columns)
	check_msa_change = '_' in first_col
	previous = ""
	msa_number += 1
	for col in columns
		if check_msa_change
			fields = split(col, '_')
			current = first(fields)
			if current != previous
				if previous != ""
					msa_number += 1
				end
				previous = string(current)
			end
			col = last(fields)
		end
		push!(colnames, "$(msa_number)_$col")
	end
	msa_number
end

function _h_concatenated_col_names(msas...)
	colnames = String[]
	msa_number = 0
	for msa in msas
		columns = columnname_iterator(msa)
		msa_number = _hcat_colnames_kernel!(colnames, columns, msa_number)
	end
	colnames
end

_get_seq_lengths(msas...) = Int[ncolumns(msa) for msa in msas]

function _get_annot_types(fun, index, data::Annotations...)
	union(Set(k[index] for k in keys(fun(annot))) for annot in data)
end

function _h_concatenate_annotfile(data::Annotations...)
	N = length(data)
	annotfile = copy(getannotfile(data[1]))
	for i in 2:N
		ann = data[i]::Annotations
		for (k, v) in getannotfile(ann)
			if haskey(annotfile, k)
				if k == "ColMap"
					annotfile[k] = string(annotfile[k], ",", v)
				else
					annotfile[k] = string(annotfile[k], "_&_", v)
				end
			else
				push!(annotfile, k => v)
			end
		end
	end
	annotfile
end

"""
It returns a Dict mapping the MSA number and sequence name to the horizontally 
concatenated sequence name.
"""
function _get_seqname_mapping_hcat(concatenated_seqnames, msas...)
	mapping = Dict{Tuple{Int, String}, String}()
	nmsa = length(msas)
	nseq = length(concatenated_seqnames)
	for j in 1:nmsa
		seq_names = sequencenames(msas[j])
		@assert nseq == length(seq_names)
		for i in 1:nseq
			mapping[(j, seq_names[i])] = concatenated_seqnames[i]
		end
	end
	mapping
end

function _concatenate_annotsequence(seqname_mapping, data::Annotations...)
	annotsequence = Dict{Tuple{String,String},String}()
	for (i, ann::Annotations) in enumerate(data)
		for ((seqname, annot_name), value) in getannotsequence(ann)
			concatenated_seqname = get(seqname_mapping, (i, seqname), seqname)
			new_key = (concatenated_seqname, annot_name)
			# if we used :vcat, new_key will not be present in the dict as the
			# sequence names are disambiguated first
			if haskey(annotsequence, new_key)
				# so, we execute the following code only if we used :hcat
				sep = annot_name == "SeqMap" ? "," : "_&_"
				annotsequence[new_key] = string(annotsequence[new_key], sep, value)
			else
				push!(annotsequence, new_key => value)
			end
		end
	end
	annotsequence
end

function _fill_and_update!(dict, last, key, i, value, seq_lengths)
	if haskey(dict, key)
		if last[key] == i - 1
			dict[key] = string(dict[key], value)
		else
			previous = sum(seq_lengths[(last[key]+1):(i-1)])
			dict[key] = string(dict[key], repeat(" ", previous), value)
		end
		last[key] = i
	else
		if i == 1
			push!(dict, key => value)
		else
			previous = sum(seq_lengths[1:(i-1)])
			push!(dict, key => string(repeat(" ", previous), value))
		end
		push!(last, key => i)
	end
end

function _fill_end!(dict, seq_lengths, entity)
	total_length = sum(seq_lengths)
	for (key, value) in dict
		current_length = length(value)
		if current_length < total_length
			dict[key] *= " "^(total_length - current_length)
		elseif current_length > total_length
			throw(ErrorException(
				"There are $current_length $entity annotated instead of $total_length."))
		end
	end
	dict
end

function _h_concatenate_annotcolumn(seq_lengths::Vector{Int}, 
		data::Annotations...)::Dict{String,String}
	annotcolumn = Dict{String,String}()
	last = Dict{String,Int}()
	for (i, ann::Annotations) in enumerate(data)
		for (annot_name, value) in getannotcolumn(ann)
			_fill_and_update!(annotcolumn, last, annot_name, i, value, seq_lengths)
		end
	end
	_fill_end!(annotcolumn, seq_lengths, "columns")
end

function _h_concatenate_annotresidue(seq_lengths, seqname_mapping, data::Annotations...)
	annotresidue = Dict{Tuple{String,String},String}()
	last = Dict{Tuple{String,String},Int}()
	for (i, ann) in enumerate(data)
		for ((seqname, annot_name), value) in getannotresidue(ann)
			concatenated_seqname = get(seqname_mapping, (i, seqname), seqname)
			new_key = (concatenated_seqname, annot_name)
			_fill_and_update!(annotresidue, last, new_key, i, value, seq_lengths)
		end
	end
	_fill_end!(annotresidue, seq_lengths, "residues")
end

function Base.hcat(msa::T...) where T <: AnnotatedAlignedObject
	seqnames = _h_concatenated_seq_names(msa...)
	colnames = _h_concatenated_col_names(msa...)
	concatenated_matrix = hcat(getresidues.(msa)...)
	concatenated_msa = _namedresiduematrix(concatenated_matrix, seqnames, colnames)
	seqname_mapping = _get_seqname_mapping_hcat(seqnames, msa...)
	seq_lengths = _get_seq_lengths(msa...)
	old_annot = annotations.([msa...])
	new_annot = Annotations(
		_h_concatenate_annotfile(old_annot...),
		_concatenate_annotsequence(seqname_mapping, old_annot...),
		_h_concatenate_annotcolumn(seq_lengths, old_annot...),
		_h_concatenate_annotresidue(seq_lengths, seqname_mapping, old_annot...)
	)
	if haskey(new_annot.file, "HCat")
		delete!(new_annot.file, "HCat")
	end
	setannotfile!(
		new_annot, 
		"HCat", 
		join((replace(col, r"_[0-9]+$" => "") for col in colnames), ',')
	)
	T(concatenated_msa, new_annot)
end

function Base.hcat(msa::T...) where T <: UnannotatedAlignedObject
	concatenated_matrix = hcat(getresidues.(msa)...)
	seqnames = _h_concatenated_seq_names(msa...)
	colnames = _h_concatenated_col_names(msa...)
	concatenated_msa = _namedresiduematrix(concatenated_matrix, seqnames, colnames)
	T(concatenated_msa)
end


"""
It returns a vector of numbers from `1` to N for each column that indicates the source MSA.
The mapping is annotated in the `"HCat"` file annotation of an
`AnnotatedMultipleSequenceAlignment` or in the column names of an `NamedArray` or
`MultipleSequenceAlignment`.
"""
function gethcatmapping(msa::AnnotatedMultipleSequenceAlignment)
    annot = getannotfile(msa)
    if haskey(annot, "HCat")
        return _str2int_mapping(annot["HCat"])
    else
        return gethcatmapping(namedmatrix(msa))
    end
end

function gethcatmapping(msa::NamedResidueMatrix{AT}) where AT <: AbstractMatrix
	colnames = columnname_iterator(msa)
	if !isempty(colnames)
		if !occursin('_', first(colnames))
			throw(ErrorException(
				"The column names have not generated by `hcat` on an `AnnotatedMultipleSequenceAlignment` or `MultipleSequenceAlignment`."
				))
		end
    	Int[ parse(Int, replace(col, r"_[0-9]+$" => "")) for col in colnames]
	else
		throw(ErrorException("There are not column names!"))
	end
end

gethcatmapping(msa::MultipleSequenceAlignment) = gethcatmapping(namedmatrix(msa))

## vcat (vertical concatenation)

"""
If returns a vector of sequence names for the vertically concatenated MSA. The prefix 
is the number associated to the source MSA. If the sequence name has already a number
as prefix, the MSA number is increased accordingly.
"""
function _v_concatenated_seq_names(msas...)
	label_mapping = Dict{String,Int}()
	concatenated_names = String[]
	msa_number = 0
	previous_msa_number = 0
	for msa in msas
		msa_label = ""
		msa_number += 1
		for seqname in sequencename_iterator(msa)
			m = match(r"^([0-9]+)_(.*)$", seqname)
			if m === nothing
				msa_label = ""
				new_seqname = "$(msa_number)_$seqname"
			else
				# if the sequence name has already a number as prefix, we increase the
				# MSA number every time the prefix number changes
				current_msa_label = string(m.captures[1])
				if current_msa_label == msa_label
					new_seqname = "$(msa_number)_$(m.captures[2])"
				else
					# avoid increasing the MSA number two times in a row the first time 
					# we find a sequence name with a number as prefix
					if msa_label != ""
						msa_number += 1
					end
					msa_label = current_msa_label
					push!(label_mapping, msa_label => msa_number)
					new_seqname = "$(msa_number)_$seqname"
				end
			end
			previous_msa_number = msa_number
			push!(concatenated_names, new_seqname)
		end
	end
	concatenated_names, label_mapping
end

"""
It returns a Dict mapping the MSA number and sequence name to the vertically 
concatenated sequence name.
"""
function _get_seqname_mapping_vcat(concatenated_seqnames, msas...)
	mapping = Dict{Tuple{Int, String}, String}()
	sequence_number = 0
	for (i, msa) in enumerate(msas)
		for seq in sequencename_iterator(msa)
			sequence_number += 1
			mapping[(i, seq)] = concatenated_seqnames[sequence_number]
		end
	end
	mapping
end

function _update_annotation_name(annot_name, msa_number, label_mapping)
	m = match(r"^([0-9]+)_(.*)$", annot_name)
	if m !== nothing && haskey(label_mapping, m.captures[1])
		# The annotation name has already a number as prefix, so we use the mapping
		# to determine the corresponding MSA number
		msa_number = label_mapping[m.captures[1]]
		new_annot_name = "$(msa_number)_$(m.captures[2])"
	else
		new_annot_name = "$(msa_number)_$annot_name"
	end
	msa_number, new_annot_name
end

function _v_concatenate_annotfile(label_mapping::Dict{String,Int}, data::Annotations...)
	annotfile = OrderedDict{String,String}()
	msa_number = 0
	for ann::Annotations in data
		msa_number += 1
		for (name, annotation) in getannotfile(ann)
			msa_number, new_name = _update_annotation_name(name, msa_number, label_mapping)
			push!(annotfile, new_name => annotation)
		end
	end
	annotfile
end

"""
Column annotations are disambiguated by adding a prefix to the annotation name as
we do for the sequence names.
"""
function _v_concatenate_annotcolumn(label_mapping::Dict{String,Int}, data::Annotations...)
	annotcolumn = Dict{String,String}()
	msa_number = 0
	for ann::Annotations in data
		msa_number += 1
		for (name, annotation) in getannotcolumn(ann)
			msa_number, new_name = _update_annotation_name(name, msa_number, label_mapping)
			push!(annotcolumn, new_name => annotation)
		end
	end
	annotcolumn
end

"""
Residue annotations are disambiguated by adding a prefix to the sequence name holding
the annotation as we do for the sequence names.
"""
function _v_concatenate_annotresidue(concatenated_seqnames, data::Annotations...)
	annotresidue = Dict{Tuple{String,String},String}()
	for (i, ann::Annotations) in enumerate(data)
		for ((seqname, annot_name), value) in getannotresidue(ann)
			concatenated_seqname = get(concatenated_seqnames, (i, seqname), seqname)
			new_key = (concatenated_seqname, annot_name)
			push!(annotresidue, new_key => value)
		end
	end
	annotresidue
end

function Base.vcat(msa::T...) where T <: AnnotatedAlignedObject
	seqnames, label_mapping = _v_concatenated_seq_names(msa...)
	colnames = columnname_iterator(msa[1])
	concatenated_matrix = vcat(getresidues.(msa)...)
	concatenated_msa = _namedresiduematrix(concatenated_matrix, seqnames, colnames)
	seqname_mapping = _get_seqname_mapping_vcat(seqnames, msa...)
	old_annot = annotations.([msa...])
	new_annot = Annotations(
		_v_concatenate_annotfile(label_mapping, old_annot...),
		_concatenate_annotsequence(seqname_mapping, old_annot...),
		_v_concatenate_annotcolumn(label_mapping, old_annot...),
		_v_concatenate_annotresidue(seqname_mapping, old_annot...)
	)
	#=
	if haskey(new_annot.file, "VCat")
		delete!(new_annot.file, "VCat")
	end
	setannotfile!(
		new_annot, 
		"VCat", 
		join((replace(seq, r"_[0-9]+$" => "") for seq in seqnames), ',')
	)
	=#
	T(concatenated_msa, new_annot)
end

function Base.vcat(msa::T...) where T <: UnannotatedAlignedObject
	concatenated_matrix = vcat(getresidues.(msa)...)
	seqnames, label_mapping = _v_concatenated_seq_names(msa...)
	colnames = columnname_iterator(msa[1])
	concatenated_msa = _namedresiduematrix(concatenated_matrix, seqnames, colnames)
	T(concatenated_msa)
end

## join



