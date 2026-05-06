### Function Definitions ###

abstract type IceFloePreprocessingAlgorithm end

@kwdef struct Preprocess <: IceFloePreprocessingAlgorithm
    diffusion_algorithm = PeronaMalikDiffusion(λ=0.1, K=0.1, niters=5, g="exponential")
    adapthisteq_params = (nbins=256, rblocks=8, cblocks=8, clip=0.99) # rblocks/cblocks not used yet -- add with CLAHE.jl
    unsharp_mask_params = (radius=50, amount=0.2, threshold=0.01)
end

function (p::Preprocess)(
    truecolor_image::AbstractArray{<:Union{AbstractRGB,TransparentRGB}}, 
    landmask,
    cloud_mask
)
    # Cast to grayscale first to save compute time
    proc_img = Gray.(truecolor_image)
    apply_landmask!(proc_img, landmask .|| cloud_mask)

    # Diffusion and sharpening
    proc_img .= nonlinear_diffusion(proc_img, p.diffusion_algorithm)

    adjust_histogram!(proc_img,
        ContrastLimitedAdaptiveHistogramEqualization(
            nbins=p.adapthisteq_params.nbins,
            rblocks=p.adapthisteq_params.rblocks,
            cblocks=p.adapthisteq_params.cblocks,
            clip=p.adapthisteq_params.clip)
    )

    proc_img .= unsharp_mask(proc_img,
        p.unsharp_mask_params.radius,
        p.unsharp_mask_params.amount,
        p.unsharp_mask_params.threshold
    )
            
    apply_landmask!(proc_img, landmask .|| cloud_mask)
    return proc_img
end

function se_disk(r)
    se = [sum(abs.(c.I .- (r + 1)) .^ 2) for c in CartesianIndices((2*r + 1, 2*r + 1))]
    return sqrt.(se) .<= r
end

function clean_binary_floes(binary_img, icemask, cloudmask;
        erosion_strel=strel_box((7,7)),
        filling_strel=strel_diamond((3,3)),
        max_fill=100
    )
    out = deepcopy(binary_img)
    # 1. Shrink objects using the provided structuring element
    eroded_img = erode(out, erosion_strel)

    # 2. After shrinking, fill holes
    filled = fill_holes(eroded_img, filling_strel) # Test how permissive this is. Should we use imfill instead?

    # 3. Identify filled holes which are part of the ice mask or the cloud mask
    filled .= filled .&& (icemask .|| cloudmask)
    filled .= .!imfill(.!filled, (0, max_fill))

    # 4. Use morphological closing to further limit openings
    closing!(filled)

    # 5. Finally, set any of these filled pixels to 1 in the output image.
    out[filled .> 0] .= 1
    return out
end

# Expand labels by distance without overlap
function expand_labels(labels, distance)
    labels_out = deepcopy(labels)
    maximum(labels_out) == 0 && return labels_out
    F = feature_transform(labels .> 0)
    D = distance_transform(F)
    labels_out[D .<= distance] .= labels[F][D .<= distance]
    return labels_out
end

# Find markers by selecting locations greater than dist threshold from background
function dist_morph_split(
        binary_floes::BitMatrix;
        min_floe_size::Int64=64,
        max_hole_fill::Int64=2000,
        max_distance::Int64=5,
        max_expand::Int64=3,
        strel=se_disk(3)
    )
    bw = .!imfill(binary_floes, (0, min_floe_size))
    dist = distance_transform(feature_transform(bw))
    levels = Dict(0 => label_components(opening(dist .> 0, strel))) # Initialize with one run of opening
    ### Build pyramid ###
    for dist_threshold in 1:max_distance
        markers = opening(dist .> dist_threshold, strel)
        markers .= .!imfill(.!markers, (0, 2000))
        levels[dist_threshold] = label_components(markers)
    end
    final_labels = deepcopy(levels[max_distance])

    ### Descend pyramid ####
    for dist_threshold in max_distance:-1:1
        # Get indices of next level down
        indices = component_indices(levels[dist_threshold - 1])

        # Expand indices of current level
        expanded = expand_labels(levels[dist_threshold], max_expand)
        for L in keys(indices)
            (L > 0) && begin
                matched_labels = unique(levels[dist_threshold][indices[L]])
                
                # If no higher levels or only one higher level, set to current label
                if (0 ∈ matched_labels) && (length(matched_labels) <= 2)
                    final_labels[indices[L]] .= L
                else
                    # Otherwise, expand the current level, and set the next level down to the expanded indices.
                    # May need to check the number of matched labels in the expanded image.
                    levels[dist_threshold - 1][indices[L]] .= expanded[indices[L]]
                    final_labels[indices[L]] .= expanded[indices[L]]
                end
            end
        end
    end
    final_labels .= label_components(final_labels)
    areas = component_lengths(final_labels)
    indices = component_indices(final_labels)
    for L in keys(areas)
        (areas[L] < min_floe_size) && (final_labels[indices[L]] .= 0)
    end
    return final_labels
end