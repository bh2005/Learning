import os
import argparse
import urllib.parse
import sys

def generate_tree_lines(start_path, relative_to):
    """
    Generates a list of strings for a Markdown list tree, with correct indentation and links.
    """
    tree_lines = []
    
    # Walk the directory tree to get all paths and files
    for root, dirs, files in os.walk(start_path):
        # Calculate the indentation level
        level = root.replace(start_path, '').count(os.sep)
        indentation = "  " * level
        
        # Add the directory to the tree
        dir_name = os.path.basename(root)
        if dir_name: # Don't list the base directory itself here
            tree_lines.append(f"{indentation}- {dir_name}")
            
        # Add the files to the tree with correct indentation and links
        for f in sorted(files):
            file_path = os.path.join(root, f)
            rel_path = os.path.relpath(file_path, relative_to)
            encoded_path = urllib.parse.quote(rel_path.replace("\\", "/"))
            
            # The indentation for files is one level deeper than the directory
            file_indentation = "  " * (level + 1)
            tree_lines.append(f"{file_indentation}- [{f}]({encoded_path})")
            
    return tree_lines

def main():
    """
    Main function to parse command-line arguments and run the script.
    """
    script_dir = os.path.dirname(os.path.abspath(sys.argv[0]))
    
    parser = argparse.ArgumentParser(
        description="Generate a linked Markdown directory tree.",
        epilog="""
Usage Examples:

    # Scan the directory where the script is located
    python dir_tree_to_md.py

    # Scan a specific directory and save to a custom file
    python dir_tree_to_md.py "C:\path\to\target" --output my_tree.md

    # Scan with a custom title and output file
    python dir_tree_to_md.py . --title "Project Docs" --output README.md
"""
    )
    
    parser.add_argument('directory', nargs='?', default=script_dir,
                        help="The path to the directory to be scanned. Defaults to the script's directory.")
    parser.add_argument('--output', type=str, default='README.md',
                        help="The name of the output Markdown file.")
    parser.add_argument('--title', type=str, default="Überschrift",
                        help="The main title for the Markdown file.")
    
    args = parser.parse_args()
    
    target_dir = os.path.abspath(args.directory)
    output_file = args.output
    main_title = args.title
    
    output_dir = os.path.dirname(os.path.abspath(output_file))
    
    if not os.path.isdir(target_dir):
        print(f"Error: The directory '{target_dir}' does not exist.")
        return
    
    print(f"Generating directory tree for '{target_dir}'...")
    
    tree_lines = generate_tree_lines(target_dir, output_dir)
    base_dir_name = os.path.basename(target_dir)
    
    # Construct the final Markdown content
    md_content = f"# {main_title}\n\n"
    md_content += f"## Directory Tree for {base_dir_name}\n\n"
    md_content += f"- **{base_dir_name}**\n" # The base directory as a bold list item
    md_content += "\n".join(tree_lines)
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(md_content)
        
    print(f"Successfully saved the tree to '{output_file}'.")

if __name__ == "__main__":
    main()