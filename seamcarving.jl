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

# ╔═╡ 32d5788f-35fa-4e9b-8464-4bc5936779e7
# Load Packages
begin
	import Pkg
	Pkg.activate(mktempdir())
	Pkg.add([
		Pkg.PackageSpec(name="ImageIO", version="0.5"),
		Pkg.PackageSpec(name="ImageShow", version="0.2"),
		Pkg.PackageSpec(name="FileIO", version="1.6"),
		Pkg.PackageSpec(name="PNGFiles", version="0.3.6"),
		Pkg.PackageSpec(name="ImageMagick", version="1"),
        Pkg.PackageSpec(name="ImageFiltering", version="0.6"),
		Pkg.PackageSpec(name="Colors", version="0.12"),
		Pkg.PackageSpec(name="ColorVectorSpace", version="0.8"),
			
		Pkg.PackageSpec(name="PlutoUI", version="0.7"),  
		Pkg.PackageSpec(name="Plots", version="1"),  
	])

	using Colors, ColorVectorSpace, ImageShow, FileIO
	using ImageFiltering
	using Plots, PlutoUI

	using Statistics, LinearAlgebra  # standard libraries available in any environment
end

# ╔═╡ 1d8d150a-dca6-11eb-1e83-0bbd3424105a
md"""
#### Seam Carving

The idea of seam carving is to shrink an image by removing the "least interesting" parts of the image, but without resizing the objects within the image. We want to remove the "dead space" within the image.
"""

# ╔═╡ 5e2e0226-01d2-4a93-acb0-bcfc067064ff
md"""
We will use Sobel filters for edge detection and write an algorithm that removes the uninteresting bits of an image.
"""

# ╔═╡ 64f45dde-0374-4b33-a02c-b1421cfc31b2
# Grab image
image_url = "https://static.seetheworld.com/image_uploader/photos/f5/original/underwater-ecomuseum-to-open-in-the-french-riviera-ile-sainte-marguerite.jpg"

# ╔═╡ bfe73692-8d47-475a-8b1a-fe6741270ec6
# Load image
img = load(download(image_url))

# ╔═╡ d11220a6-d90b-4498-9591-dea0d1d878f9
begin
	# Use a weighted sum of rgb giving more weight to colors we perceive as 'brighter'
	brightness(c::AbstractRGB) = 0.3 * c.r + 0.59 * c.g + 0.11 * c.b

	# Turn it into grayscale
	Gray.(brightness.(img))
end

# ╔═╡ 18b33617-a38f-4ebc-b0a5-ec3c65da36c5
md"""
#### Edge Detection Filter


Through the use of Sobel Edge Detection.


```math
\begin{align}

G_x &= \begin{bmatrix}
1 & 0 & -1 \\
2 & 0 & -2 \\
1 & 0 & -1 \\
\end{bmatrix} \star A\\[10pt]
G_y &= \begin{bmatrix}
1 & 2 & 1 \\
0 & 0 & 0 \\
-1 & -2 & -1 \\
\end{bmatrix} \star A
\end{align}
```

Here, $\star$ denotes convolution.

Here $A$ is the array corresponding to your image.
We can think of $G_x$ and $G_y$ as calculating (discretized) **derivatives** in the $x$ and $y$ directions.

Then we combine them by finding the magnitude of the (discretized) **gradient**, in the sense of multivariate calculus, by defining

$$G_\text{total} = \sqrt{G_x^2 + G_y^2}.$$
"""

# ╔═╡ 0379f9d4-221b-423f-90ad-1c5045a16ab3
md"""
Here are the Sobel kernels for the derivatives in each direction:
"""

# ╔═╡ 27aea04d-bf8e-4ff2-8646-dbed8d9deab7
Sy, Sx = Kernel.sobel()

# ╔═╡ 9fde3ea5-caea-4dc6-be44-1b130724fbb9
# Declare functions and wrap them in a block.
begin
	function hbox(x, y, gap=16; sy=size(y), sx=size(x))
		w,h = (max(sx[1], sy[1]),
			   gap + sx[2] + sy[2])

		slate = fill(RGB(1,1,1), w,h)
		slate[1:size(x,1), 1:size(x,2)] .= RGB.(x)
		slate[1:size(y,1), size(x,2) + gap .+ (1:size(y,2))] .= RGB.(y)
		slate
	end


	function show_colored_array(array)
		pos_color = RGB(0.36, 0.82, 0.8)
		neg_color = RGB(0.99, 0.18, 0.13)
		to_rgb(x) = max(x, 0) * pos_color + max(-x, 0) * neg_color
		to_rgb.(array) / maximum(abs.(array))
	end
	
	function convolve(M, kernel)
		height, width = size(kernel)

		half_height = height ÷ 2
		half_width = width ÷ 2

		new_image = similar(M)

		# (i, j) loop over the original image
		m, n = size(M)
		@inbounds for i in 1:m
			for j in 1:n
				# (k, l) loop over the neighbouring pixels
				accumulator = 0 * M[1, 1]
				for k in -half_height:-half_height + height - 1
					for l in -half_width:-half_width + width - 1
						Mi = i - k
						Mj = j - l
						# First index into M
						if Mi < 1
							Mi = 1
						elseif Mi > m
							Mi = m
						end
						# Second index into M
						if Mj < 1
							Mj = 1
						elseif Mj > n
							Mj = n
						end

						accumulator += kernel[k, l] * M[Mi, Mj]
					end
				end
				new_image[i, j] = accumulator
			end
		end

		return new_image
	end
	
	function edgeness(img)
		Sy, Sx = Kernel.sobel()
		b = brightness.(img)

		∇y = convolve(b, Sy)
		∇x = convolve(b, Sx)

		sqrt.(∇x.^2 + ∇y.^2)
	end
	
	function shrink_image(image, ratio=5)
		(height, width) = size(image)
		new_height = height ÷ ratio - 1
		new_width = width ÷ ratio - 1
		list = [
			mean(image[
				ratio * i:ratio * (i + 1),
				ratio * j:ratio * (j + 1),
			])
			for j in 1:new_width
			for i in 1:new_height
		]
		reshape(list, new_height, new_width)
	end
	
	function mark_path(img, path)
		img′ = copy(img)
		m = size(img, 2)

		for (i, j) in path
			# To make it easier to see, we'll color not just
			# the pixels of the seam, but also those adjacent to it

			for j′ in j-1:j+1
				img′[i, clamp(j′, 1, m)] = RGB(1,0,1)
			end

		end

		return img′
	end
	
	function pencil(X)
		f(x) = RGB(1-x,1-x,1-x)
		map(f, X ./ maximum(X))
	end
	
end

# ╔═╡ 8cdd4397-bd56-417f-b650-0cf8bd38298e
hbox(show_colored_array(Sx).parent, show_colored_array(Sy).parent ,10)

# ╔═╡ 2a0971bb-4ae2-4f79-9dd2-efe3fd2c08b9
(collect(Int.(8 .* Sx)), collect(Int.(8 .* Sy)))

# ╔═╡ 4720bda2-ca3c-47ed-891c-f1d9c3e58f05
begin
	img_brightness = brightness.(img)
	∇x = convolve(img_brightness, Sx)
	∇y = convolve(img_brightness, Sy)
	hbox(show_colored_array(∇x), show_colored_array(∇y))
end

# ╔═╡ d00fafdf-b21e-4332-a292-b1cfd5a920ac
plotly()

# ╔═╡ 119c9326-6dd4-4631-abfe-16f295e0f0c1
surface(brightness.(img))

# ╔═╡ 573d5222-6d71-4de4-98eb-19ec19193ba2
let
	vbox(x,y, gap=16) = hbox(x', y')'
	∇y = convolve(brightness.(img), Sy)
	∇x = convolve(brightness.(img), Sx)
	# zoom in on the clock
	vbox(
		hbox(img[300:end, 1:300], img[300:end, 1:300]), 
	 	hbox(show_colored_array.((∇x[300:end,  1:300], ∇y[300:end, 1:300]))...)
	)
end

# ╔═╡ 34036b75-f002-41e0-ac89-02bcc60af895
begin
	edged = edgeness(img)
	# hbox(img, pencil(edged))
	hbox(img, Gray.(edgeness(img)) / maximum(abs.(edged)))
end

# ╔═╡ 8b0108d2-5a8e-453a-90b8-9bc89c01a949
md"""


What if we wanted to just find the path that minimizes the number of edges it crosses? 
"""

# ╔═╡ 76b3d310-3729-4f57-8e49-495b2b61c919
# Create a function.

function least_edgy(E)
	least_E = zeros(size(E))
	dirs = zeros(Int, size(E))
	
	least_E[end, :] .= E[end, :] # the minimum energy on the last row is the energy
	                             # itself

	m, n = size(E)
	# Go from the last row up, finding the minimum energy
	
	for i in m-1:-1:1
		for j in 1:n
			
			j1, j2 = max(1, j-1), min(j+1, n)
			e, dir = findmin(least_E[i+1, j1:j2])
			least_E[i,j] += e
			least_E[i,j] += E[i,j]
			dirs[i, j] = (-1,0,1)[dir + (j==1)]
			
		end
	end
	
	return least_E, dirs
end

# ╔═╡ 50b4d04e-8ea3-456b-ba8e-ce8fe07456ce
least_e, dirs = least_edgy(edgeness(img))

# ╔═╡ 52427259-ac34-4de5-8343-29ae4c338ddb
show_colored_array(least_e)

# ╔═╡ 9e034ff0-f897-4a5e-b351-e5b1453586b4
md"## Remove seams"

# ╔═╡ d836de71-5648-449d-8a12-fc70a1ba766b
function get_seam_at(dirs, j)
	m = size(dirs, 1)
	js = fill(0, m)
	js[1] = j
	
	for i=2:m
		js[i] = js[i-1] + dirs[i-1, js[i-1]]
	end
	
	return tuple.(1:m, js)
end

# ╔═╡ 36187bf7-0aef-4fcb-bc29-b2c005191694
get_seam_at(dirs, 2)

# ╔═╡ c87986aa-4eac-49c0-a595-a9cd751a6b4c
@bind start_column Slider(1:size(img, 2), show_value=true)

# ╔═╡ f64eff54-34dc-4019-a155-089d9e97d583
path = get_seam_at(dirs, start_column)

# ╔═╡ df9e271e-25ad-4748-b9bf-94d83471c812
hbox(mark_path(img, path), mark_path(show_colored_array(least_e), path))

# ╔═╡ 0d64abac-856b-44c3-964f-97e6e7370164
e = edgeness(img);

# ╔═╡ f4d2c7ae-2e7b-4028-9a24-e1e4751c997d
let
	hbox(mark_path(img, path), mark_path(pencil(e), path));
end

# ╔═╡ 8abbf23d-4d65-468d-b6f3-75288a73dbce
let
	# least energy path of them all:
	_, k = findmin(least_e[1, :])
	path = get_seam_at(dirs, k)
	hbox(
		mark_path(img, path),
		mark_path(show_colored_array(least_e), path)
	)
end

# ╔═╡ aca80585-1610-4eb0-9c1e-0e9e76f85792
function rm_path(img, path)
	img′ = img[:, 1:end-1] # one less column
	for (i, j) in path
		img′[i, 1:j-1] .= img[i, 1:j-1]
		img′[i, j:end] .= img[i, j+1:end]
	end
	img′
end

# ╔═╡ 922e6b3b-70a2-42e9-a950-250178089cf8
function shrink_n(img, n)
	imgs = []
	marked_imgs = []

	e = edgeness(img)
	for i=1:n
		least_E, dirs = least_edgy(e)
		_, min_j = findmin(@view least_E[1, :])
		seam = get_seam_at(dirs, min_j)
		img = rm_path(img, seam)
		# Recompute the energy for the new image
		# Note, this currently involves rerunning the convolution
		# on the whole image, but in principle the only values that
		# need recomputation are those adjacent to the seam, so there
		# is room for a meanintful speedup here.
#		e = edgeness(img)
		e = rm_path(e, seam)

 		push!(imgs, img)
 		push!(marked_imgs, mark_path(img, seam))
	end
	imgs, marked_imgs
end

# ╔═╡ fd965440-fdbc-4aa3-bee5-ec99c771897f
n_examples = min(200, size(img, 2))

# ╔═╡ a984544c-9f25-4b28-a9d4-c1e48cb0ea01
carved, marked_carved = shrink_n(img, n_examples);

# ╔═╡ 511db69f-1d27-45f9-87d3-926c96bc8be1
@bind n Slider(1:length(carved))

# ╔═╡ a88c2ecf-b470-4d17-b823-6d9a7cd5e302
hbox(img, marked_carved[n], sy=size(img))

# ╔═╡ Cell order:
# ╟─1d8d150a-dca6-11eb-1e83-0bbd3424105a
# ╟─5e2e0226-01d2-4a93-acb0-bcfc067064ff
# ╠═32d5788f-35fa-4e9b-8464-4bc5936779e7
# ╠═64f45dde-0374-4b33-a02c-b1421cfc31b2
# ╠═bfe73692-8d47-475a-8b1a-fe6741270ec6
# ╠═d11220a6-d90b-4498-9591-dea0d1d878f9
# ╟─18b33617-a38f-4ebc-b0a5-ec3c65da36c5
# ╟─0379f9d4-221b-423f-90ad-1c5045a16ab3
# ╠═27aea04d-bf8e-4ff2-8646-dbed8d9deab7
# ╠═9fde3ea5-caea-4dc6-be44-1b130724fbb9
# ╠═8cdd4397-bd56-417f-b650-0cf8bd38298e
# ╠═2a0971bb-4ae2-4f79-9dd2-efe3fd2c08b9
# ╠═4720bda2-ca3c-47ed-891c-f1d9c3e58f05
# ╠═d00fafdf-b21e-4332-a292-b1cfd5a920ac
# ╠═119c9326-6dd4-4631-abfe-16f295e0f0c1
# ╠═573d5222-6d71-4de4-98eb-19ec19193ba2
# ╠═34036b75-f002-41e0-ac89-02bcc60af895
# ╟─8b0108d2-5a8e-453a-90b8-9bc89c01a949
# ╠═76b3d310-3729-4f57-8e49-495b2b61c919
# ╠═50b4d04e-8ea3-456b-ba8e-ce8fe07456ce
# ╠═52427259-ac34-4de5-8343-29ae4c338ddb
# ╟─9e034ff0-f897-4a5e-b351-e5b1453586b4
# ╠═d836de71-5648-449d-8a12-fc70a1ba766b
# ╠═36187bf7-0aef-4fcb-bc29-b2c005191694
# ╠═c87986aa-4eac-49c0-a595-a9cd751a6b4c
# ╠═f64eff54-34dc-4019-a155-089d9e97d583
# ╠═df9e271e-25ad-4748-b9bf-94d83471c812
# ╠═0d64abac-856b-44c3-964f-97e6e7370164
# ╠═f4d2c7ae-2e7b-4028-9a24-e1e4751c997d
# ╠═8abbf23d-4d65-468d-b6f3-75288a73dbce
# ╠═aca80585-1610-4eb0-9c1e-0e9e76f85792
# ╠═922e6b3b-70a2-42e9-a950-250178089cf8
# ╠═fd965440-fdbc-4aa3-bee5-ec99c771897f
# ╠═a984544c-9f25-4b28-a9d4-c1e48cb0ea01
# ╠═511db69f-1d27-45f9-87d3-926c96bc8be1
# ╠═a88c2ecf-b470-4d17-b823-6d9a7cd5e302
