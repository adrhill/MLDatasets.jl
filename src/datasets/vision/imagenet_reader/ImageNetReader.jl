module ImageNetReader
using ImageCore: channelview, colorview, AbstractRGB, RGB

import ..FileDataset
import ..read_mat
import ..@lazy

@lazy import JpegTurbo = "b835a17e-a41a-41e7-81f0-2f016b05efe0"

const NCLASSES = 1000
const IMGSIZE = (224, 224)

include("preprocess.jl")

function get_file_dataset(Tx::Type{<:Real}, preprocess::Function, dir::AbstractString)
    # Construct a function that loads images from FileDataset path,
    # applies preprocessing and converts to type Tx.
    function load_image(file::AbstractString)
        im = JpegTurbo.jpeg_decode(RGB{Tx}, file; preferred_size=IMGSIZE)
        return Tx.(preprocess(im))
    end
    return FileDataset(load_image, dir, "*.JPEG")
end
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


# Get WordNet ID from path
load_wnids(d::FileDataset) = load_wnids(d.paths)
load_wnids(fs::AbstractVector{<:AbstractString}) = [split(f, "/")[end - 1] for f in fs]

end # ImageNetReader module
