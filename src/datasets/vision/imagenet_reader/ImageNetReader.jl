module ImageNetReader
import ..FileDataset
import ..read_mat
import ..@lazy

@lazy import JpegTurbo = "b835a17e-a41a-41e7-81f0-2f016b05efe0"
@lazy import Images = "916415d5-f1e6-5110-898d-aaa5f9f070e0"

include("preprocess.jl")

const NCLASSES = 1000

function read_metadata(file::AbstractString)
    meta = read_mat(file)["synsets"]
    is_child = iszero.(meta["num_children"])
    @assert meta["ILSVRC2012_ID"][is_child] == 1:NCLASSES

    metadata = Dict{String,Any}()
    metadata["class_WNIDs"] = Vector{String}(meta["WNID"][is_child]) # WordNet IDs
    metadata["class_names"] = split.(meta["words"][is_child], ", ")
    metadata["class_description"] = Vector{String}(meta["gloss"][is_child])
    metadata["wnid_to_label"] = Dict(metadata["class_WNIDs"] .=> 1:NCLASSES)
    return metadata
end

# The full ImageNet dataset doesn't fit into memory, so we only save filenames
readdata(dir::AbstractString) = FileDataset(identity, dir, "*.JPEG").paths

# Get WordNet ID from path
function load_wnids(files::AbstractVector{<:AbstractString})
    return [split(f, "/")[end - 1] for f in files]
end

# Load image from ImageNetFile path and preprocess it to normalized 224x224x3 Array{Tx,3}
function readimage(Tx::Type{<:Real}, path::AbstractString)
    im = JpegTurbo.jpeg_decode(Images.RGB{Tx}, path; preferred_size=(224, 224))
    return preprocess(Tx, im)
end

# Load batched array of images
cat_batchdim(xs...) = cat(xs...; dims=4)
function readimage(Tx::Type, is::AbstractVector{<:AbstractString})
    return reduce(cat_batchdim, readimage(Tx, i) for i in is)
end

end # module
