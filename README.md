# Git Auto-Deploy Script

A flexible bash script for automatically deploying Git repositories to a Linux server without requiring deployment agents. Features manual deployment control via flag files and supports both root and sub-site deployments.

## Features

- **No deployment agents required** - Pure bash and Git
- **Manual deployment control** - Deploy only when you explicitly enable it
- **Safe root deployments** - Preserves non-Git files in root directory
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
/usr/local/bin/deploy-site.sh <repo_dir> <sub-site>
```

**Parameters:**
- `<repo_dir>` - The base directory containing your Git repository
- `<sub-site>` - Either `-` for root directory or the sub-site folder name

### Examples

**Deploy root directory:**
```bash
/usr/local/bin/deploy-site.sh /var/www/html -
```

**Deploy sub-site:**
```bash
/usr/local/bin/deploy-site.sh /var/www/html myapp
```

## Configuring Cron

### Edit crontab

```bash
crontab -e
```

### Single site deployment

Check every 5 minutes for root site:
```cron
*/5 * * * * /usr/local/bin/deploy-site.sh /var/www/html -
```

### Multiple site deployments

Deploy root and multiple sub-sites:
```cron
*/5 * * * * /usr/local/bin/deploy-site.sh /var/www/html -
*/5 * * * * /usr/local/bin/deploy-site.sh /var/www/html myapp
*/5 * * * * /usr/local/bin/deploy-site.sh /var/www/html blog
*/5 * * * * /usr/local/bin/deploy-site.sh /var/www/html api
```

### Custom schedules

```cron
# Every hour
0 * * * * /usr/local/bin/deploy-site.sh /var/www/html -

# Every 15 minutes
*/15 * * * * /usr/local/bin/deploy-site.sh /var/www/html myapp

# Every day at 3 AM
0 3 * * * /usr/local/bin/deploy-site.sh /var/www/html blog
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
3. Git pull executes
4. Flag is automatically recreated
5. Future deployments are blocked until you remove the flag again

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

### Root Directory Deployment (`-`)

When deploying to root directory:

1. **Safe deployment** - Pulls to temporary directory `/tmp/main`
2. **File-by-file copy** - Copies only Git-managed files to `REPO_DIR`
3. **Preserves existing files** - Non-Git files remain untouched
4. **Auto-lock** - Creates `hold_deploy.txt` after successful deployment

**Use case:** When `REPO_DIR` contains configuration files, logs, or other non-Git content that shouldn't be deleted.

### Sub-Site Deployment

When deploying to a sub-site:

1. **Direct pull** - Executes `git pull` directly in the sub-site directory
2. **Faster** - No temporary directory or file copying
3. **Standard Git behavior** - Works like a normal `git pull`
4. **Auto-lock** - Creates `hold_deploy.txt` in the sub-site directory

**Use case:** When the sub-site directory is entirely managed by Git.

## Monitoring Deployments

### View deployment log

```bash
tail -f /var/log/deploy-site.log
```

### Log entry format

```
Sat Nov  8 14:23:15 EST 2025 [myapp] : No deploy flag found, starting deployment
Sat Nov  8 14:23:16 EST 2025 [myapp] : Deployment complete, flag created to block future deployments
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

**For cron user access:**
```bash
# If running cron as specific user
sudo chown username:username /var/www/html
```

### Git authentication issues

**For HTTPS repositories:**
```bash
# Set up credential caching
git config --global credential.helper cache
```

**For SSH repositories:**
```bash
# Ensure SSH key is set up
ssh-keygen -t ed25519 -C "your_email@example.com"
# Add public key to GitHub/GitLab
```

### Sub-site directory not found

**Error in logs:**
```
ERROR - Sub-site directory does not exist: /var/www/html/myapp
```

**Solution:**
```bash
# Create the sub-site directory and initialize Git
mkdir -p /var/www/html/myapp
cd /var/www/html/myapp
git clone <your-repo-url> .
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
/usr/local/bin/deploy-site.sh /var/www/html -
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
```

### Git credentials

- Use SSH keys instead of passwords
- For HTTPS, use credential helpers or tokens
- Never commit credentials to repositories

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

Modify the script to change branch:
```bash
# Replace this line:
git pull origin main

# With:
git pull origin production
```

### Email notifications

Add to script after deployment:
```bash
echo "Deployment completed for $SUB_SITE" | mail -s "Deploy Success" admin@example.com
```

### Webhook integration

Create a webhook endpoint that removes the flag:
```bash
# webhook.php
<?php
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    unlink('/var/www/html/hold_deploy.txt');
    echo "Deployment enabled";
}
?>
```

Configure GitHub/GitLab webhook to call this endpoint after push.

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
```

## Support

For issues or questions:
- Check the log file: `/var/log/deploy-site.log`
- Test script manually with verbose output
- Verify Git repository status: `git status`
- Check cron execution: `grep CRON /var/log/syslog`