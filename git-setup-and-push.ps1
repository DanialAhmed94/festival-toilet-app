# Run this script in PowerShell from outside Cursor (e.g. Windows Terminal)
# so no other process holds the git lock.

$repoPath = "d:\projects\Crapadviser Backup- 16 March 26\festival-toilet-app"
Set-Location $repoPath

# Remove stale lock if any
if (Test-Path .git\index.lock) {
    Remove-Item .git\index.lock -Force -ErrorAction SilentlyContinue
}

# Unstage everything so .gitignore is respected (avoids build files and LF/CRLF warnings)
git reset

# Stage only non-ignored files (respects .gitignore)
git add .

# Show what will be committed
git status

git commit -m "Festival Toilet App"
Write-Host ""
Write-Host "Commit done. To push, add your remote and push:"
Write-Host '  git remote add origin <YOUR_REPO_URL>'
Write-Host "  git branch -M main"
Write-Host "  git push -u origin main"
Write-Host ""
Write-Host "Replace <YOUR_REPO_URL> with e.g. https://github.com/username/repo.git"
