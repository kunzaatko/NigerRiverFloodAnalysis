using CairoMakie
CairoMakie.activate!()

FIGURE_DIR = "./report/figures/"


"""
    save_fig(fig, name, project_dir)

Save a figure in both SVG and PDF formats.

# Parameters:
    - `fig`: figure object to save
    - `name`: name of the file to save the figure as
    - `project_dir`: relative or absolute path to the project directory

This function saves a figure object in both SVG and PDF formats. The SVG file is saved in the parent directory with the given name and the extension ".svg". The PDF file is saved in the same directory with the given name and the extension ".pdf". The Inkscape command is used to convert the SVG file to PDF format with text in LaTeX using PDF_TEX.
"""
function save_fig(fig, name, project_dir=".."; dpi=800, varargs...)
    fig_dir = joinpath(project_dir, FIGURE_DIR)
    svg_path = fig_dir * name * ".svg"
    Makie.save(svg_path, fig; varargs...)
    pdf_path = fig_dir * name * ".pdf"
    inkscape_cmd = Cmd(["inkscape", svg_path, "--export-area-page", "--export-dpi", string(dpi), "--export-type=pdf", "--export-latex", "--export-filename", pdf_path])
    run(inkscape_cmd)
end

return save_fig
