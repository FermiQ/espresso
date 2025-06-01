import re
import argparse
import os

def parse_fortran_file(filepath):
    """
    Parses a Fortran file to extract basic documentation information with a focus on performance.
    """
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
    except Exception as e:
        print(f"Error reading file {filepath}: {e}")
        return None # Skip file if reading fails

    parsed_data = {
        "name": os.path.basename(filepath), # Default to filename if no module/program found
        "overview": "No overview found.",
        "components": [], # List of names
        "dependencies": []  # List of module names
    }

    # --- Module/Program Name ---
    # Search for module or program statement, prefer module if both somehow exist
    module_match = re.search(r"^\s*module\s+(\w+)", content, re.IGNORECASE | re.MULTILINE)
    if module_match:
        parsed_data["name"] = module_match.group(1)
        # Search for overview starting from after the module statement
        content_after_decl = content[module_match.end():]
    else:
        program_match = re.search(r"^\s*program\s+(\w+)", content, re.IGNORECASE | re.MULTILINE)
        if program_match:
            parsed_data["name"] = program_match.group(1)
            content_after_decl = content[program_match.end():]
        else:
            # If no module or program statement, use the whole content for overview search
            content_after_decl = content

    # --- Overview ---
    # Try specific tags first (single line only)
    summary_match = re.search(r"^\s*!!\s*(?:Summary|@brief):\s*(.+)", content_after_decl, re.IGNORECASE | re.MULTILINE)
    if summary_match:
        parsed_data["overview"] = summary_match.group(1).strip()
    else:
        # Fallback to the very first comment line after program/module declaration
        first_comment_match = re.search(r"^\s*!!?\s*(.+)", content_after_decl, re.MULTILINE)
        if first_comment_match:
            parsed_data["overview"] = first_comment_match.group(1).strip()

    # --- Dependencies (USE statements) ---
    # Simplified: just extract the module name
    # Regex: find "use module_name" (potentially with comma or only)
    use_matches = re.finditer(r"^\s*use\s+([a-z0-9_]+)", content, re.IGNORECASE | re.MULTILINE)
    for match in use_matches:
        module_name = match.group(1)
        if module_name.lower() != "only": # basic check to avoid 'only' keyword as module
             if module_name not in parsed_data["dependencies"]: # Avoid duplicates
                parsed_data["dependencies"].append(module_name)

    # --- Key Components (Subroutines/Functions names only) ---
    # Simplified: find "subroutine name" or "function name"
    # This regex will not capture parameters or anything else, just the name.
    # It looks for the keyword, then the name, then an optional parenthesis.
    component_matches = re.finditer(
        r"^\s*(?:recursive\s+|elemental\s+)*" # Optional prefixes
        r"(subroutine|function)\s+([a-z0-9_]+)",  # Type and Name (parameter list matching removed)
        content, re.IGNORECASE | re.MULTILINE
    )
    for match in component_matches:
        comp_name = match.group(2) # Group 2 is the name
        parsed_data["components"].append(comp_name)

    return parsed_data

def generate_markdown(parsed_data, fortran_filename):
    """
    Generates simplified Markdown content.
    """
    md_filename = os.path.splitext(fortran_filename)[0] + ".md"
    md_content = [f"# {parsed_data['name']}", "\n## Overview", parsed_data['overview']]

    if parsed_data['components']:
        md_content.append("\n## Key Components")
        for name in parsed_data['components']:
            md_content.append(f"- `{name}`")
    else:
        md_content.append("\n## Key Components")
        md_content.append("None found.")

    # Removed Variables/Constants section

    if parsed_data['dependencies']:
        md_content.append("\n## Dependencies")
        for dep_name in parsed_data['dependencies']:
            md_content.append(f"- `USE {dep_name}`")
    else:
        md_content.append("\n## Dependencies")
        md_content.append("None found.")

    # Removed Examples section

    return md_filename, "\n".join(md_content)

def main():
    parser = argparse.ArgumentParser(description="Generate simplified Markdown documentation from Fortran source files.")
    parser.add_argument("files", metavar="FILE", type=str, nargs='+',
                        help="Fortran source files to process")
    parser.add_argument("-o", "--output-dir", type=str, default=".",
                        help="Directory to save generated Markdown files (default: current directory)")

    args = parser.parse_args()

    if not os.path.exists(args.output_dir):
        os.makedirs(args.output_dir)
        print(f"Created output directory: {args.output_dir}")

    for fortran_file_path in args.files:
        print(f"Processing {fortran_file_path}...")
        try:
            fortran_filename = os.path.basename(fortran_file_path)
            parsed_data = parse_fortran_file(fortran_file_path)

            if parsed_data is None: # Skip if file reading failed
                continue

            md_filename, md_content = generate_markdown(parsed_data, fortran_filename)
            output_filepath = os.path.join(args.output_dir, md_filename)

            print(f"  Generating Markdown for {output_filepath}")
            with open(output_filepath, 'w', encoding='utf-8') as f:
                f.write(md_content)
            print(f"  Successfully generated {output_filepath}")

        except Exception as e:
            print(f"Error processing {fortran_file_path}: {e}")
            import traceback
            traceback.print_exc()

if __name__ == "__main__":
    main()
