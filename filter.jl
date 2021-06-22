### A Pluto.jl notebook ###
# v0.14.8

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ 1629a458-1403-4773-8f02-4dd34cd6bb24
begin
	import Pkg
	Pkg.activate(mktempdir())
	Pkg.add([
		Pkg.PackageSpec(name="ImageIO", version="0.5"),
		Pkg.PackageSpec(name="ImageShow", version="0.2"),
		Pkg.PackageSpec(name="FileIO", version="1.6"),
		Pkg.PackageSpec(name="PNGFiles", version="0.3.6"),
		Pkg.PackageSpec(name="Colors", version="0.12"),
		Pkg.PackageSpec(name="ColorVectorSpace", version="0.8"),
		
		Pkg.PackageSpec(name="PlutoUI", version="0.7"), 
		Pkg.PackageSpec(name="Unitful", version="1.6"), 
		Pkg.PackageSpec(name="ImageFiltering", version="0.6"),
		Pkg.PackageSpec(name="OffsetArrays", version="1.6"),
		Pkg.PackageSpec(name="Plots", version="1.10")
	])

	using PlutoUI 
	using Colors, ColorVectorSpace, ImageShow, FileIO
	using Unitful 
	using ImageFiltering
	using OffsetArrays
	using Plots
end

# ╔═╡ 62e31e4c-d316-11eb-1c15-ef5a8b4686b2
# Downsampling / Upsampling
pixelated_polar = load(download("https://image.freepik.com/free-vector/cartoon-polar-bear-pixel-style_61878-528.jpg"))

# ╔═╡ b27e4334-09a9-4d98-9f0b-adec90fdcd63
polar = load(download("https://upload.wikimedia.org/wikipedia/commons/0/09/Polar_Bear_-_Alaska.jpg"))

# ╔═╡ 6ee1b041-3efa-4e33-b3b1-9a34480fb9d3
@bind r Slider(1:40, show_value=true, default=40)

# ╔═╡ b074dcb6-0f05-4307-93a9-ddeb1bbeedd4
downsample_polar = polar[1:r:end, 1:r:end]

# ╔═╡ f40b2a16-ff3f-4271-8e58-5a66e80bd135
upsample_polar = kron(downsample_polar, fill(1,r,r))

# ╔═╡ 66c8acdb-8126-4199-84f0-b2a9fa2e9af9
# Scale intensity
@bind c Slider(0:.1:3, show_value=true, default=1)


# ╔═╡ a7d866f5-ab01-4018-b5bb-8ad1794096d4
# You might wonder about the dot times or pointwise times. You can delete the dot, but it is recommended for clarity and performance. The dot emphasizes that the multiplication by c is happening pixel by pixel or that the scalar is being "broadcast" to every pixel.
c .* polar

# ╔═╡ d7e84595-1164-455b-a3a3-e93768d29ef2
upsidedown_polar = polar[ end:-1:1 , :]

# ╔═╡ b1c45318-52df-4152-b489-34a7d6ba4a5a
# Scaled images.
(.5 * upsidedown_polar .+ .5 * polar) 

# ╔═╡ aacd5a3b-15aa-4708-9d20-8548c2ce04d8
# Convex combinations
 @bind α Slider(0:.01:1 , show_value=true, default = 1.0)

# ╔═╡ 8d9e6ef0-456e-45a6-90ac-d41f34eb3340
α .* polar .+ (1-α) .* upsidedown_polar

# ╔═╡ 7180d447-2403-4b97-8eb4-b8d9adee84d6
# Computer Science: Complexity

# The number of multiplications = (Number of Pixels in the Image) * (Number of Cells in the kernel)

# ╔═╡ 088b642f-ce68-489a-9a3f-c6909f6003a0
# Smaller kernels are better
 kernelize(M) = OffsetArray( M, -1:1, -1:1)	   

# ╔═╡ 49d6cd2e-1911-482c-b56b-e403e3215e6d
# We change properties here.
begin
	identity = [0 0 0 ; 0 1 0 ; 0 0 0]
	edge_detect = [0 -1 0; -1 4 -1; 0 -1 0] 
	sharpen = identity .+ edge_detect  # Superposition!
	box_blur = [1 1 1;1 1 1;1 1 1]/9
	∇x = [-1 0 1;-1 0 1;-1 0 1]/2 # centered deriv in x
	∇y = ∇x'
	
	kernels = [identity, edge_detect, sharpen, box_blur, ∇x, ∇y]
	kernel_keys =["identity", "edge_detect", "sharpen", "box_blur", "∇x", "∇y"]
	selections = kernel_keys .=> kernel_keys
	kernel_matrix = Dict(kernel_keys .=> kernels)
	md"$(@bind kernel_name Select(selections))"
end

# ╔═╡ b296a130-14ce-4586-9e71-ca8c725e343e
# Displayes the matrix for the selected filter.
kernel_matrix[kernel_name]

# ╔═╡ 67ca4b31-82a1-4164-bd10-a2da0d319aec
[imfilter( polar, kernelize(kernel_matrix[kernel_name])) Gray.(1.5 .* abs.(imfilter( polar, kernelize(kernel_matrix[kernel_name])))) ]

# ╔═╡ 7fc8fda5-9f00-443e-874e-ff7c56559893
# Gaussian filter
round.(Kernel.gaussian(1), digits=3)

# ╔═╡ 06d61b45-d05c-40fc-82c2-14913d51e259
# Manual definition of the above function through an exponential function.
begin
	G = [exp( -(i^2+j^2)/2) for i=-2:2, j=-2:2]
	round.(G ./ sum(G), digits=3)
end

# ╔═╡ 44a14a2b-b542-4b06-b84a-ac9d5c7bd432
@bind gparam Slider(0:9, show_value=true, default=1)

# ╔═╡ 5963e1b2-9c0b-4257-83b9-a0be397111b8
kernel = Kernel.gaussian(gparam)

# ╔═╡ cb21d52b-2d45-439d-919e-b19a7a19355c
plotly()

# ╔═╡ 6d610db6-0fcb-4b95-b1d6-ddd5cd889931
surface([kernel;])

# ╔═╡ eb888a69-540c-4bc1-8fe4-9aeb2e4fc498
M = [ 1  2  3  4  5
	  6  7  8  9 10
	 11 12 13 14 15]

# ╔═╡ 499ba833-e17a-4655-b192-8fca9d0cf211
Z = OffsetArray(M, -1:1, -2:2)

# ╔═╡ 2a9bd9ff-3660-4e42-8106-7d3a50d55e71
the_indices = [ c.I for c ∈ CartesianIndices(Z)]

# ╔═╡ 6ba905c9-1b41-407c-9c8d-89aa04e84652
Z[1,-2]

# ╔═╡ 3548bb0c-ee52-4295-a2bd-17c05455b12e
# Note: Blurring Kernels :: Integrals ≡ Sharpening Kernels :: Derivatives

# ╔═╡ Cell order:
# ╠═1629a458-1403-4773-8f02-4dd34cd6bb24
# ╠═62e31e4c-d316-11eb-1c15-ef5a8b4686b2
# ╠═b27e4334-09a9-4d98-9f0b-adec90fdcd63
# ╠═6ee1b041-3efa-4e33-b3b1-9a34480fb9d3
# ╠═b074dcb6-0f05-4307-93a9-ddeb1bbeedd4
# ╠═f40b2a16-ff3f-4271-8e58-5a66e80bd135
# ╠═66c8acdb-8126-4199-84f0-b2a9fa2e9af9
# ╠═a7d866f5-ab01-4018-b5bb-8ad1794096d4
# ╠═d7e84595-1164-455b-a3a3-e93768d29ef2
# ╠═b1c45318-52df-4152-b489-34a7d6ba4a5a
# ╠═aacd5a3b-15aa-4708-9d20-8548c2ce04d8
# ╠═8d9e6ef0-456e-45a6-90ac-d41f34eb3340
# ╠═7180d447-2403-4b97-8eb4-b8d9adee84d6
# ╠═088b642f-ce68-489a-9a3f-c6909f6003a0
# ╠═49d6cd2e-1911-482c-b56b-e403e3215e6d
# ╠═b296a130-14ce-4586-9e71-ca8c725e343e
# ╠═67ca4b31-82a1-4164-bd10-a2da0d319aec
# ╠═7fc8fda5-9f00-443e-874e-ff7c56559893
# ╠═06d61b45-d05c-40fc-82c2-14913d51e259
# ╠═44a14a2b-b542-4b06-b84a-ac9d5c7bd432
# ╠═5963e1b2-9c0b-4257-83b9-a0be397111b8
# ╠═cb21d52b-2d45-439d-919e-b19a7a19355c
# ╠═6d610db6-0fcb-4b95-b1d6-ddd5cd889931
# ╠═eb888a69-540c-4bc1-8fe4-9aeb2e4fc498
# ╠═499ba833-e17a-4655-b192-8fca9d0cf211
# ╠═2a9bd9ff-3660-4e42-8106-7d3a50d55e71
# ╠═6ba905c9-1b41-407c-9c8d-89aa04e84652
# ╠═3548bb0c-ee52-4295-a2bd-17c05455b12e
