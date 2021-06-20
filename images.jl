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

# ╔═╡ b374b202-d187-11eb-1108-07325d07c6c3
# This takes approximately 75 seconds for the first time.
begin
	import Pkg
	Pkg.activate(mktempdir())
	Pkg.add([
		Pkg.PackageSpec(name="Images", version="0.22.4"), 	
		Pkg.PackageSpec(name="ImageIO", version="0.5"),
		Pkg.PackageSpec(name="ImageShow", version="0.2"),
		Pkg.PackageSpec(name="FileIO", version="1.6"),
		Pkg.PackageSpec(name="PNGFiles", version="0.3.6"),
		Pkg.PackageSpec(name="Colors", version="0.12"),
		Pkg.PackageSpec(name="ColorVectorSpace", version="0.8"),
		Pkg.PackageSpec(name="PlutoUI", version="0.7"), 
		Pkg.PackageSpec(name="HypertextLiteral", version="0.5")
	])
	using Images
	using Colors, ColorVectorSpace, ImageShow, FileIO
	using PlutoUI
	using HypertextLiteral
end

# ╔═╡ 37c94d53-e89d-436e-b538-a0f580aec451
# This is my walkthrough of the MIT Computational Thinking Course for Spring 2021.

# ╔═╡ 30875eda-508d-4c60-a716-86c4dd589c22
# Polar bear images. we can group up multiple statements within a begin and end.
begin
	# defining url
	url = "https://chinadialogueocean.net/wp-content/uploads/2020/09/china-dialogue-ocean-melting-ice-caps-polar-bears-1440x720.jpg"
	
	# download image to our temporary drive
	verne_file = download(url)
end

# ╔═╡ 48c50318-363a-4208-a31f-39d41cf85b00
# Load data. There's a need to load the package "ImageMagick" inside Julia.
verne = load(verne_file) 

# ╔═╡ 20ed281a-8160-4113-8789-b88e03f8fd10
# Check size of the image.
verne_size = size(verne)

# ╔═╡ 85c2928c-0691-43e2-8ed0-51f6421fb408
# Check height of the image.
verne_height = verne_size[1]

# ╔═╡ 0b06ac52-9aec-4510-bed0-81fa18b53c26
# Check width of the image.
verne_width = verne_size[2]

# ╔═╡ 9a60d4b3-4c64-49b8-b764-1076780847ea
# Check locations inside an image.
a_pixel = verne[400, 600]

# ╔═╡ f14fdf16-a345-486d-87e7-782e7b7ca996
# Create sliders similar to the ipython thing for row and column
begin
	@bind row_i Slider(1:size(verne)[1], show_value=true)
	@bind col_i Slider(1:size(verne)[2], show_value=true)
end 

# ╔═╡ c79adccc-1b14-4d72-baad-e47b1ae918d6
# If you use the slider above the pixel changes the color instantly.
verne[row_i, col_i]

# ╔═╡ 14839212-dc8f-4345-8f75-6609c5874031
# Range indexing to show part of an image.
verne[550:650, 1:verne_width]

# ╔═╡ 19910cf5-282e-4908-a172-1100ebf0f317
# All numbers
collect(1:10)

# ╔═╡ a2b2a10c-dc11-4e36-9626-c05d65a8646f
# The colon means "every index".
verne[550:650, :]

# ╔═╡ 68123007-6290-4b78-ae9e-9f366c47d1a4
# Single row of pixels.
verne[550, :]

# ╔═╡ ed222803-f769-45b7-a4bc-1ff2d61643d7
# Let's try to get the head of one of the polar bears.
polar_head = verne[120:290, 475:675]

# ╔═╡ 404c690e-723c-4459-bdac-c9abfd90b963
# Scrolling for rows
@bind range_rows RangeSlider(1:size(polar_head)[1])

# ╔═╡ 1e85020f-65a6-488a-8c8f-63e373bc560b
# Scrolling for columns
@bind range_cols RangeSlider(1:size(polar_head)[2])

# ╔═╡ 139b2c18-7194-47bc-97a3-ad7634aaec3b
# Use the scrolling features to zoom in the part that you want.
nose = polar_head[range_rows, range_cols]

# ╔═╡ a9a43222-c603-4e70-8d36-2ccac5acb55b
# Define a color
RGB(1.0, 0.0, 0.0)

# ╔═╡ 8a995fe3-4737-46a5-bfc5-4eebf6f7ba66
# Modify a color. Can be only values between 0 and 1.
RGB(0.0, 0.5, 0.0)

# ╔═╡ 560460d3-bd4b-4a5a-9f0a-8f3fa76b0cff
# Invert function
function invert(color::AbstractRGB)
	return RGB(1-color.r, 1-color.g, 1-color.b)
end

# ╔═╡ 0686cd59-cea3-4189-a397-fe907416629f
# Define the color black.
black = RGB(0.0, 0.0, 0.0)

# ╔═╡ a5cc71a1-9c59-4681-933d-c4118fc0c3fb
invert(black)

# ╔═╡ 6a59ae15-f3d6-4a9d-906e-d422c5528ee4
# Define red.
red = RGB(0.8, 0.1, 0.1)

# ╔═╡ 88e42030-183a-45ab-9ed3-5e73e8b98648
invert(red)

# ╔═╡ 9d573cbe-8f34-4ca4-a426-a7fb4544dd47
# Sadly we cannot invert the image.
verne_inverted = invert(verne)

# ╔═╡ 298ccb96-9fba-453b-a13c-6ae3aff23e2f
# Modify pixel in an image with red.
let
	temp = copy(polar_head)
	temp[100, 200] = RGB(1.0, 0.0, 0.0)
	temp
end

# ╔═╡ 983cc7f7-592b-4e70-afe1-cb8dd39e0810
# Displays strip as a row of rectangles
polar_head[50, 50:100]

# ╔═╡ 994c3df5-5e5f-495b-8823-d22f39e977a7
# Draw a red line above the eye.
let
	temp = copy(polar_head)
	temp[55, 50:100] .= RGB(1.0, 0.0, 0.0)
	temp
end

# ╔═╡ d16d0498-845b-4e8f-985b-79090de37d47
# What about a "black" i mean "block of pixels"?
let
	temp = copy(polar_head)
	temp[60:83, 60:83] .= RGB(0.0, 0.0, 0.0)
	temp
end

# ╔═╡ fa396f59-24e1-48b5-839c-0c6e510b6914
# Generate a bar of 100 zeroes.
function create_bar()
	x = zeros(100)
	x[40:59] .= 1
	return x
end

# ╔═╡ 51dafd41-c840-476d-829c-ace078cb0aaf
# Reduce size of the image.
reduced_image = verne[1:10:end, 1:10:end]

# ╔═╡ 1b275517-31b8-45f5-a6d1-9b5303c4c46e
# Save output.
save("reduced_verne.png", reduced_image)

# ╔═╡ 7354317b-7fd5-4e34-b1bb-0a43d182c202
# Arrays.
[1, 20, "hello"]

# ╔═╡ 92f0a174-9309-4a43-8cce-8d3586f2bb03
# One Dimensional
[RGB(1, 0, 0), RGB(0, 1, 0), RGB(0, 0, 1)]

# ╔═╡ 1ee0ee66-738e-4ea9-901d-8439947f7d05
# Two Dimensional
[RGB(1, 0, 0)  RGB(0, 1, 0)
 RGB(0, 0, 1)  RGB(0.5, 0.5, 0.5)]

# ╔═╡ 6c658410-0c55-46cd-b06e-926112c46b93
# Array comprehension.
[RGB(x, 0, 0) for x in 0:0.1:1]

# ╔═╡ e64631bf-9971-42d4-9356-d4885c256d91
# Matrix
[RGB(i, j, 0) for i in 0:0.1:1, j in 0:0.1:1]

# ╔═╡ 16b3dada-1035-42ce-929c-42818f46ddca
# Joining matrices.
[polar_head                   reverse(polar_head, dims=2)
 reverse(polar_head, dims=1)  rot180(polar_head)]

# ╔═╡ cd8bba7f-4d5a-4d11-8bf2-4610e8d1e521
# Color slider.
@bind number_reds Slider(1:100, show_value=true)

# ╔═╡ bc73f38b-10c3-4f09-a8d5-235aa94a8e8c
[RGB(red_value / number_reds, 0, 0) for red_value in 0:number_reds]

# ╔═╡ Cell order:
# ╠═37c94d53-e89d-436e-b538-a0f580aec451
# ╠═b374b202-d187-11eb-1108-07325d07c6c3
# ╠═30875eda-508d-4c60-a716-86c4dd589c22
# ╠═48c50318-363a-4208-a31f-39d41cf85b00
# ╠═20ed281a-8160-4113-8789-b88e03f8fd10
# ╠═85c2928c-0691-43e2-8ed0-51f6421fb408
# ╠═0b06ac52-9aec-4510-bed0-81fa18b53c26
# ╠═9a60d4b3-4c64-49b8-b764-1076780847ea
# ╠═f14fdf16-a345-486d-87e7-782e7b7ca996
# ╠═c79adccc-1b14-4d72-baad-e47b1ae918d6
# ╠═14839212-dc8f-4345-8f75-6609c5874031
# ╠═19910cf5-282e-4908-a172-1100ebf0f317
# ╠═a2b2a10c-dc11-4e36-9626-c05d65a8646f
# ╠═68123007-6290-4b78-ae9e-9f366c47d1a4
# ╠═ed222803-f769-45b7-a4bc-1ff2d61643d7
# ╠═404c690e-723c-4459-bdac-c9abfd90b963
# ╠═1e85020f-65a6-488a-8c8f-63e373bc560b
# ╠═139b2c18-7194-47bc-97a3-ad7634aaec3b
# ╠═a9a43222-c603-4e70-8d36-2ccac5acb55b
# ╠═8a995fe3-4737-46a5-bfc5-4eebf6f7ba66
# ╠═560460d3-bd4b-4a5a-9f0a-8f3fa76b0cff
# ╠═0686cd59-cea3-4189-a397-fe907416629f
# ╠═a5cc71a1-9c59-4681-933d-c4118fc0c3fb
# ╠═6a59ae15-f3d6-4a9d-906e-d422c5528ee4
# ╠═88e42030-183a-45ab-9ed3-5e73e8b98648
# ╠═9d573cbe-8f34-4ca4-a426-a7fb4544dd47
# ╠═298ccb96-9fba-453b-a13c-6ae3aff23e2f
# ╠═983cc7f7-592b-4e70-afe1-cb8dd39e0810
# ╠═994c3df5-5e5f-495b-8823-d22f39e977a7
# ╠═d16d0498-845b-4e8f-985b-79090de37d47
# ╠═fa396f59-24e1-48b5-839c-0c6e510b6914
# ╠═51dafd41-c840-476d-829c-ace078cb0aaf
# ╠═1b275517-31b8-45f5-a6d1-9b5303c4c46e
# ╠═7354317b-7fd5-4e34-b1bb-0a43d182c202
# ╠═92f0a174-9309-4a43-8cce-8d3586f2bb03
# ╠═1ee0ee66-738e-4ea9-901d-8439947f7d05
# ╠═6c658410-0c55-46cd-b06e-926112c46b93
# ╠═e64631bf-9971-42d4-9356-d4885c256d91
# ╠═16b3dada-1035-42ce-929c-42818f46ddca
# ╠═cd8bba7f-4d5a-4d11-8bf2-4610e8d1e521
# ╠═bc73f38b-10c3-4f09-a8d5-235aa94a8e8c
