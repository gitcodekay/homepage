# Git Auto-Deploy Script

A flexible bash script for automatically deploying Git repositories to a Linux server without requiring deployment agents. Features manual deployment control via flag files and performs fresh clones to ensure latest code deployment.

## Features

- **No deployment agents required** - Pure bash and Git
- **Manual deployment control** - Deploy only when you explicitly enable it
- **Fresh clone every deployment** - Always get the latest code from GitHub
- **Safe file copying** - Preserves non-Git files in destination directory
- **Multi-site support** - Deploy multiple sub-sites independently
- **Comprehensive logging** - Track all deployment activity
- **Cron-based automation** - Check for deployments on your schedule

## Installation

### 1. Create the deployment script

```bash
sudo nano /usr/local/bin/deploy-site.sh
```

Paste the script content and save.

### 2. Make it executable

```bash
sudo chmod +x /usr/local/bin/deploy-site.sh
```

### 3. Create log file (optional)

```bash
sudo touch /var/log/deploy-site.log
sudo chmod 666 /var/log/deploy-site.log
```

### 4. Initialize deployment flags

Create the hold flag to block deployments initially:

```bash
# For root site
touch /var/www/html/hold_deploy.txt

# For sub-sites
touch /var/www/html/myapp/hold_deploy.txt
touch /var/www/html/blog/hold_deploy.txt
```

## Usage

### Script Syntax

```bash
/usr/local/bin/deploy-site.sh <git_url> <build_dir> <dest_dir> <sub-site>
```

**Parameters:**
- `<git_url>` - GitHub repository clone URL (HTTPS or SSH)
- `<build_dir>` - Build/workspace directory where repo will be cloned
- `<dest_dir>` - Destination directory for deployment
- `<sub-site>` - Either `-` for root directory or the sub-site folder name

### Examples

**Deploy root directory:**
```bash
/usr/local/bin/deploy-site.sh \
  https://github.com/user/repo.git \
  /tmp/build-main \
  /var/www/html \
  -
```

**Deploy sub-site:**
```bash
/usr/local/bin/deploy-site.sh \
  https://github.com/user/myapp.git \
  /tmp/build-myapp \
  /var/www/html \
  myapp
```

**Deploy with SSH URL:**
```bash
/usr/local/bin/deploy-site.sh \
  git@github.com:user/blog.git \
  /tmp/build-blog \
  /var/www/html \
  blog
```

## Configuring Cron

### Edit crontab

```bash
crontab -e
```

### Single site deployment

Check every 5 minutes for root site:
```cron
*/5 * * * * /usr/local/bin/deploy-site.sh https://github.com/user/repo.git /tmp/build-main /var/www/html -
```

### Multiple site deployments

Deploy root and multiple sub-sites:
```cron
*/5 * * * * /usr/local/bin/deploy-site.sh https://github.com/user/repo.git /tmp/build-main /var/www/html -
*/5 * * * * /usr/local/bin/deploy-site.sh https://github.com/user/myapp.git /tmp/build-myapp /var/www/html myapp
*/5 * * * * /usr/local/bin/deploy-site.sh https://github.com/user/blog.git /tmp/build-blog /var/www/html blog
*/5 * * * * /usr/local/bin/deploy-site.sh https://github.com/user/api.git /tmp/build-api /var/www/html api
```

### Custom schedules

```cron
# Every hour
0 * * * * /usr/local/bin/deploy-site.sh https://github.com/user/repo.git /tmp/build-main /var/www/html -

# Every 15 minutes
*/15 * * * * /usr/local/bin/deploy-site.sh https://github.com/user/myapp.git /tmp/build-myapp /var/www/html myapp

# Every day at 3 AM
0 3 * * * /usr/local/bin/deploy-site.sh https://github.com/user/blog.git /tmp/build-blog /var/www/html blog
```

## Deployment Control

### Enable Deployment (Deploy Once)

Remove the hold flag to allow the next deployment:

```bash
# Root site
rm /var/www/html/hold_deploy.txt

# Sub-site
rm /var/www/html/myapp/hold_deploy.txt
```

**What happens:**
1. Cron runs the script
2. Flag is absent → deployment proceeds
3. Build directory is cleaned and fresh clone is performed
4. Files are copied one-by-one to destination
5. Flag is automatically recreated
6. Future deployments are blocked until you remove the flag again

### Block Deployment

Create the hold flag to prevent deployments:

```bash
# Root site
touch /var/www/html/hold_deploy.txt

# Sub-site
touch /var/www/html/myapp/hold_deploy.txt
```

### Check Deployment Status

```bash
# Check if deployment is blocked
ls -la /var/www/html/hold_deploy.txt

# If file exists → deployments blocked
# If file not found → next cron run will deploy
```

## How It Works

### Deployment Process

All deployments (root and sub-site) follow the same process:

1. **Check flag** - If `hold_deploy.txt` exists, exit silently
2. **Clean build directory** - Remove and recreate build workspace
3. **Fresh clone** - Clone repository from GitHub to build directory
4. **File-by-file copy** - Copy only Git-managed files to destination
5. **Preserve existing files** - Non-Git files in destination remain untouched
6. **Auto-lock** - Create `hold_deploy.txt` after successful deployment

### Root Directory Deployment (`-`)

When deploying to root directory:
- Copies files to `dest_dir` directly
- Preserves configuration files, logs, or other non-Git content
- Flag location: `dest_dir/hold_deploy.txt`

**Use case:** When destination contains configuration files, logs, or other non-Git content that shouldn't be deleted.

### Sub-Site Deployment

When deploying to a sub-site:
- Copies files to `dest_dir/sub-site` subdirectory
- Auto-creates sub-site directory if it doesn't exist
- Flag location: `dest_dir/sub-site/hold_deploy.txt`

**Use case:** Deploy multiple applications to separate subdirectories.

### Build Directory

The build directory is a temporary workspace:
- Cleaned before each deployment (ensures fresh clone)
- Contains the cloned repository during deployment
- Can be any location with write permissions
- Different build directories can be used for different sites

**Recommendation:** Use separate build directories for each site:
- `/tmp/build-main` for root site
- `/tmp/build-myapp` for myapp sub-site
- `/tmp/build-blog` for blog sub-site

## Monitoring Deployments

### View deployment log

```bash
tail -f /var/log/deploy-site.log
```

### Log entry format

```
Sat Nov  8 14:23:15 EST 2025 [myapp] : No deploy flag found, starting deployment
Sat Nov  8 14:23:16 EST 2025 [myapp] : Cloning repository from https://github.com/user/myapp.git to /tmp/build-myapp
Sat Nov  8 14:23:18 EST 2025 [myapp] : Copying files from /tmp/build-myapp to /var/www/html/myapp
Sat Nov  8 14:23:19 EST 2025 [myapp] : File copy complete
Sat Nov  8 14:23:19 EST 2025 [myapp] : Deployment complete, flag created to block future deployments
---
```

### Filter logs by sub-site

```bash
grep "\[myapp\]" /var/log/deploy-site.log
grep "\[-\]" /var/log/deploy-site.log  # Root site
```

## Workflow Example

### Typical deployment workflow:

1. **Push changes to Git**
   ```bash
   git add .
   git commit -m "Update homepage"
   git push origin main
   ```

2. **Enable deployment on server**
   ```bash
   ssh user@server
   rm /var/www/html/hold_deploy.txt
   ```

3. **Wait for cron** - Within 5 minutes (or your cron interval), deployment happens automatically

4. **Verify deployment**
   ```bash
   tail /var/log/deploy-site.log
   ```

5. **Check site** - Visit your website to confirm changes

6. **Deployment auto-locks** - The flag is recreated, blocking future deployments until you remove it again

## Troubleshooting

### Deployment not happening

**Check if flag exists:**
```bash
ls -la /var/www/html/hold_deploy.txt
```

**Solution:** Remove the flag file

### Permission errors

**Grant proper permissions:**
```bash
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html
```

**For build directory:**
```bash
sudo mkdir -p /tmp/build-main
sudo chown username:username /tmp/build-main
```

**For cron user access:**
```bash
# If running cron as specific user
sudo chown username:username /var/www/html
sudo chown username:username /tmp/build-main
```

### Git authentication issues

**For HTTPS repositories:**
```bash
# Set up credential caching
git config --global credential.helper cache

# Or use Personal Access Token in URL
https://username:token@github.com/user/repo.git
```

**For SSH repositories:**
```bash
# Ensure SSH key is set up
ssh-keygen -t ed25519 -C "your_email@example.com"
# Add public key to GitHub/GitLab

# Test SSH connection
ssh -T git@github.com
```

### Git clone fails

**Check log for errors:**
```bash
tail -50 /var/log/deploy-site.log | grep ERROR
```

**Common issues:**
- Incorrect Git URL
- Authentication failure (wrong credentials or SSH key)
- Network connectivity issues
- Repository doesn't exist or is private

**Test clone manually:**
```bash
cd /tmp
git clone https://github.com/user/repo.git test-clone
```

### Build directory errors

**Ensure build directory is writable:**
```bash
sudo mkdir -p /tmp/build-main
sudo chown $(whoami):$(whoami) /tmp/build-main
```

**Check disk space:**
```bash
df -h /tmp
```

### Sub-site directory creation fails

**Check parent directory permissions:**
```bash
ls -ld /var/www/html
sudo chmod 755 /var/www/html
```

### Cron not running

**Verify cron service:**
```bash
sudo systemctl status cron
```

**Check crontab:**
```bash
crontab -l
```

**Test script manually:**
```bash
/usr/local/bin/deploy-site.sh \
  https://github.com/user/repo.git \
  /tmp/build-main \
  /var/www/html \
  -
```

### Files not copying

**Check build directory contents:**
```bash
ls -la /tmp/build-main
```

**Verify destination permissions:**
```bash
ls -ld /var/www/html
```

**Check log for copy errors:**
```bash
grep "File copy" /var/log/deploy-site.log
```

## Security Considerations

### File permissions

Ensure proper ownership and permissions:
```bash
# Script should be owned by root
sudo chown root:root /usr/local/bin/deploy-site.sh
sudo chmod 755 /usr/local/bin/deploy-site.sh

# Web directory accessible by web server
sudo chown -R www-data:www-data /var/www/html

# Build directory accessible by cron user
sudo chown username:username /tmp/build-main
```

### Git credentials

- **Recommended:** Use SSH keys instead of passwords
- For HTTPS, use Personal Access Tokens (PAT) instead of passwords
- Never commit credentials to repositories
- Store PAT in Git credential helper:
  ```bash
  git config --global credential.helper store
  # Then clone once to store credentials
  ```

### Build directory security

- Build directory is temporary and cleaned each deployment
- Sensitive files in repository will be cloned to build directory
- Ensure build directory permissions prevent unauthorized access
- Consider using `/tmp` which is typically cleaned on reboot

### Log rotation

Prevent log file from growing too large:
```bash
sudo nano /etc/logrotate.d/deploy-site
```

Add:
```
/var/log/deploy-site.log {
    weekly
    rotate 4
    compress
    missingok
    notifempty
}
```

## Advanced Configuration

### Deploy specific branch

Modify the script to clone a specific branch:
```bash
# Replace this line in the script:
git clone "$GIT_URL" "$BUILD_DIR"

# With:
git clone -b production "$GIT_URL" "$BUILD_DIR"
```

### Run build commands

Add build steps after cloning:
```bash
# After the git clone section, add:
cd "$BUILD_DIR" || exit 1
npm install
npm run build
# Then continue with file copying
```

### Email notifications

Add to script after deployment:
```bash
echo "Deployment completed for $SUB_SITE from $GIT_URL" | \
  mail -s "Deploy Success" admin@example.com
```

### Webhook integration

Create a webhook endpoint that removes the flag:
```bash
# webhook.php
<?php
$site = $_POST['site'] ?? 'root';
$flag_path = $site === 'root' 
    ? '/var/www/html/hold_deploy.txt'
    : "/var/www/html/$site/hold_deploy.txt";

if ($_SERVER['REQUEST_METHOD'] === 'POST' && file_exists($flag_path)) {
    unlink($flag_path);
    echo "Deployment enabled for $site";
} else {
    echo "Flag not found or invalid request";
}
?>
```

Configure GitHub/GitLab webhook to call this endpoint after push.

### Custom file filtering

To exclude certain files from being copied:
```bash
# In the find command, add more exclusions:
find . -type f ! -path './.git/*' ! -path './.git' ! -name '*.log' ! -path './node_modules/*' | while read -r file; do
```

### Deploy to multiple destinations

Use the same build directory for multiple destinations:
```bash
# Build once
/usr/local/bin/deploy-site.sh https://github.com/user/repo.git /tmp/build-main /var/www/html -

# Deploy to staging (use different dest_dir)
/usr/local/bin/deploy-site.sh https://github.com/user/repo.git /tmp/build-main /var/www/staging -
```

Note: This requires modifying the script to skip the clone if build directory exists and is fresh.

## Migration from Old Version

If you're upgrading from the previous version of this script:

### Update cron jobs

Old format:
```cron
*/5 * * * * /usr/local/bin/deploy-site.sh /var/www/html -
```

New format:
```cron
*/5 * * * * /usr/local/bin/deploy-site.sh https://github.com/user/repo.git /tmp/build-main /var/www/html -
```

### Key differences

1. **Git URL parameter** - Now explicitly provided (previously inferred from destination)
2. **Build directory** - New parameter for clone workspace
3. **Unified deployment** - Both root and sub-site use same copy mechanism
4. **Fresh clone** - Always clones fresh instead of git pull
5. **No .git in destination** - Destination directory no longer needs to be a Git repository

### Migration steps

1. **Identify Git URLs** - Determine the repository URL for each deployment
2. **Choose build directories** - Select unique build directory for each site
3. **Update cron jobs** - Modify all crontab entries with new parameters
4. **Test manually** - Run script manually before enabling automatic deployment
5. **Remove old .git directories** (optional) - Clean up destination directories:
   ```bash
   rm -rf /var/www/html/.git
   rm -rf /var/www/html/myapp/.git
   ```

## Uninstallation

```bash
# Remove cron jobs
crontab -e
# Delete the deployment lines

# Remove script
sudo rm /usr/local/bin/deploy-site.sh

# Remove log file
sudo rm /var/log/deploy-site.log

# Remove flag files
rm /var/www/html/hold_deploy.txt
find /var/www/html -name "hold_deploy.txt" -delete

# Clean build directories
rm -rf /tmp/build-*
```

## Support

For issues or questions:
- Check the log file: `/var/log/deploy-site.log`
- Test script manually with verbose output
- Verify Git repository URL: `git ls-remote <git_url>`
- Check cron execution: `grep CRON /var/log/syslog`
- Verify build directory is writable
- Test Git authentication manually