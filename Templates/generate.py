import subprocess
import os


def clone_repo(author: str, repo: str):
    """
    Clone the repository at the given URL into the current directory.
    """

    url = f"https://github.com/{author}/{repo}.git"

    # Delete the target folder.
    subprocess.run(["rm", "-rf", f"Templates/repos/{author}/{repo}"])

    # Use the git command to clone the repository in the repos directory, in its own folder.
    subprocess.run(["git", "clone", url, f"Templates/repos/{author}/{repo}"])

def find_templates(root: str) -> [str]:
    """
    List the folders that contain a main.typ file.
    This operation is recursive.
    """

    # List the files in the current directory.
    files = os.listdir(root)

    # List the folders that contain a main.typ file.
    folders = []

    # Iterate over the files in the current directory.
    for file in files:

        # If the file is a directory, recursively call this function.
        if os.path.isdir(root + file):
            folders += find_templates(root + file + "/")

        # If the file is a main.typ file, add the folder to the list.
        elif file == "main.typ":
            folders.append(root)

    return folders

def generate_serifian_template(source: str):
    """
    Creates a Serifian template from the given source folder path.
    """

    # Get the name of the template.
    name = source.split("/")[-2]

    # Delete the <template>.sr folder if it exists.
    subprocess.run(["rm", "-rf", f"Templates/{name}.sr"])

    # Create a <template>.sr folder.
    os.mkdir(f"Templates/{name}.sr")

    # Copy the source folder into the <template>.sr/Typst folder.
    subprocess.run(["cp", "-r", source, f"Templates/{name}.sr/Typst"])

    # Copy the Serifian.plist file from Empty.sr into the <template>.sr folder.
    subprocess.run(["cp", "Templates/Empty.sr/Serifian.plist", f"Templates/{name}.sr"])

    # Compile a preview.pdf document with typst.
    subprocess.run(["typst", "c", f"Templates/{name}.sr/Typst/main.typ", f"Templates/{name}.sr/preview.pdf"])

    # Create a jpeg file of the first page of the preview.pdf document.
    subprocess.run(["convert", "-density", "300", f"Templates/{name}.sr/preview.pdf[0]", f"Templates/{name}.sr/preview.jpg"])

# Main
if __name__ == "__main__":

    # Clone the official Typst template repository.
    clone_repo(author="typst", repo="templates")

    # Find the folders that contain a main.typ file.
    folders = find_templates(root="Templates/repos/")

    for folder in folders:
        print(folder)
        generate_serifian_template(source=folder)