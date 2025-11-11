# Git Auto-Deploy Script - Resume Prompt / Context Resume

## Project Overview
This is a bash-based Git deployment solution for Linux servers that operates **without deployment agents**. It uses cron jobs and flag files to provide manual deployment control with automatic locking after each deployment. The script performs **fresh clones** from GitHub to a build directory, then copies files to the destination.

## Core Concept: Deploy-Once-Then-Lock Pattern
- **Default state**: Deployment is BLOCKED (flag file exists)
- **To deploy**: User removes flag file → next cron run deploys → flag auto-recreates
- **Result**: Each deployment must be manually approved by removing the flag

## Key Files
1. **deploy-site.sh** - Main deployment script (`/usr/local/bin/deploy-site.sh`)
2. **README.md** - Complete documentation with installation, usage, troubleshooting
3. **hold_deploy.txt** - Flag file that blocks deployment when present

## Script Architecture

### Parameters
```bash
deploy-site.sh <git_url> <build_dir> <dest_dir> <sub-site>
```
- `git_url`: GitHub repository clone URL (HTTPS or SSH)
- `build_dir`: Build/workspace directory for cloning repository
- `dest_dir`: Destination directory where files will be deployed
- `sub-site`: Either `-` for root or sub-site folder name

### Unified Deployment Process

**All deployments (root and sub-site) follow the same workflow:**

1. **Clean build directory** - Remove and recreate to ensure fresh state
2. **Fresh clone** - Clone repository from GitHub to build directory
3. **File-by-file copy** - Copy all files (excluding `.git`) to destination
4. **Preserve non-Git files** - Existing files in destination remain untouched
5. **Auto-lock** - Create `hold_deploy.txt` to block future deployments

### Deployment Modes

**1. Root Deployment (sub-site = "-")**
- Copies files directly to `dest_dir`
- Flag location: `dest_dir/hold_deploy.txt`
- Use case: Deploy to main web directory

**2. Sub-Site Deployment (sub-site = folder name)**
- Copies files to `dest_dir/sub-site`
- Auto-creates sub-site directory if it doesn't exist
- Flag location: `dest_dir/sub-site/hold_deploy.txt`
- Use case: Deploy multiple applications to separate subdirectories

### Key Variables
- `GIT_URL`: Repository clone URL
- `BUILD_DIR`: Temporary build/workspace location
- `DEST_DIR`: Final destination directory (renamed from `REPO_DIR`)
- `SUB_SITE`: Site identifier (`-` or folder name)
- `FULL_DEST_DIR`: Complete destination path (`DEST_DIR` or `DEST_DIR/SUB_SITE`)
- `FLAG_FILE`: Path to `hold_deploy.txt` flag
- `LOG_FILE`: `/var/log/deploy-site.log`
- `FLAG_NAME`: `hold_deploy.txt`

### Script Logic Flow
1. **Validate parameters** - Ensure all 4 parameters provided
2. **Determine paths** - Calculate `FULL_DEST_DIR` and `FLAG_FILE` based on sub-site
3. **Check flag** - If `hold_deploy.txt` exists → silent exit (blocked)
4. **Create sub-site directory** - If sub-site doesn't exist, create it
5. **Clean build directory** - `rm -rf` then `mkdir -p`
6. **Clone repository** - `git clone $GIT_URL $BUILD_DIR`
7. **Copy files** - Use `find` to copy all files except `.git` directory
8. **Create flag** - `touch $FLAG_FILE` to block future deployments
9. **Log completion** - Log all actions with timestamp and sub-site identifier

### Logging
- File: `/var/log/deploy-site.log`
- Format: `$(date) [$SUB_SITE] : message`
- Log entries:
  - "No deploy flag found, starting deployment"
  - "Cloning repository from [url] to [build_dir]"
  - "Copying files from [build_dir] to [dest_dir]"
  - "File copy complete"
  - "Deployment complete, flag created to block future deployments"
  - "ERROR - Git clone failed"
  - "Failed to change to [directory]"

## Cron Integration
- Runs script at regular intervals (typically `*/5 * * * *`)
- Each site/sub-site has independent cron entry
- Can schedule multiple sites with different frequencies
- Each site should use unique build directory

Example:
```cron
*/5 * * * * /usr/local/bin/deploy-site.sh https://github.com/user/repo.git /tmp/build-main /var/www/html -
*/5 * * * * /usr/local/bin/deploy-site.sh https://github.com/user/myapp.git /tmp/build-myapp /var/www/html myapp
```

## Important Design Decisions

### Why fresh clone instead of git pull?
- **Guarantees latest code** - No conflicts or merge issues
- **Consistent state** - Every deployment starts from clean slate
- **Simpler logic** - No need to handle git pull failures or conflicts
- **Safer** - Destination directory never needs to be a Git repository

### Why build directory?
- **Separation of concerns** - Build/clone separate from destination
- **Safe copying** - Can inspect/validate before deploying
- **Multiple deployments** - Same build can deploy to multiple destinations
- **Clean workspace** - Always start fresh, no leftover artifacts

### Why file-by-file copy?
- **Preserves non-Git files** - Configs, logs, uploads stay intact
- **No .git directory** - Destination is not a Git repository
- **Selective deployment** - Easy to filter which files to copy
- **Safer** - Won't delete existing important files

### Why flag-based control?
- **No webhooks or external agents needed**
- **Manual approval prevents accidental deployments**
- **Simple to understand and troubleshoot**
- **Works with any Git provider**

### Why auto-lock after deployment?
- **Prevents continuous deployments from eating resources**
- **Forces deliberate deployment approval**
- **Easy to track when deployments occurred**

### Why separate flags per site?
- **Independent deployment control**
- **Can deploy one site without affecting others**
- **Clearer logging and debugging**

## Common Update Scenarios

### Adding new feature to script
1. Review script logic flow above
2. Maintain flag check at start
3. Preserve fresh clone + file copy pattern
4. Update log format to include relevant info
5. Test with both `-` and sub-site parameters
6. Update README with new feature documentation

### Changing flag behavior
1. Update flag file name in `FLAG_NAME` variable
2. Update all references in script (check, create)
3. Update README sections: "Deployment Control", "How It Works"
4. Update troubleshooting section if needed

### Modifying deployment logic
- Clone: Update `git clone` command and error handling
- Copy: Update `find` command filters or copy logic
- Both: Update error handling and logging

### Adding parameters
1. Update parameter validation section
2. Document in README "Usage" and "Script Syntax"
3. Update all example commands in README and this file
4. Add to troubleshooting if complex

### Supporting additional branches
1. Modify `git clone` to include branch parameter
2. Add branch validation
3. Update cron examples with branch names
4. Document branch usage in README

## File Structure Expected
```
project.zip
├── deploy-site.sh           # Main deployment script
├── README.md                # Complete documentation
└── CONTEXT_RESUME.md        # This file
```

## Quick Reference: What Goes Where

**In deploy-site.sh:**
- Parameter validation (4 required)
- Path calculations (build, destination, flag)
- Flag checking
- Build directory cleanup
- Git clone operations
- File copying logic
- Flag creation
- Logging
- Error handling

**In README.md:**
- Installation steps
- Usage examples (all 4 parameters)
- Cron configuration examples
- Enable/block deployment instructions
- How It Works (fresh clone + copy)
- Troubleshooting (git clone, build dir, permissions)
- Security considerations
- Advanced configurations
- Migration guide from old version

**This file (CONTEXT_RESUME.md):**
- High-level architecture
- Design decisions
- Update guidance
- Quick reference
- Parameter details

## Testing Checklist for Updates
- [ ] Test root deployment with `-` parameter
- [ ] Test sub-site deployment with folder name
- [ ] Verify flag blocks deployment when present
- [ ] Verify flag removed allows deployment
- [ ] Verify flag auto-creates after deployment
- [ ] Check log entries format correctly
- [ ] Test with non-existent sub-site (should auto-create)
- [ ] Verify build directory cleanup between runs
- [ ] Test with invalid Git URL (should error)
- [ ] Test with missing parameters (should error)
- [ ] Verify file copying excludes .git directory
- [ ] Verify non-Git files preserved in destination
- [ ] Test with HTTPS and SSH Git URLs
- [ ] Verify cron execution

## Common User Issues (for README updates)
1. **Permissions** - Script, build directory, destination directory
2. **Git authentication** - SSH keys, HTTPS credentials, PAT
3. **Cron not running** - Service status, syntax errors
4. **Flag confusion** - Presence blocks vs allows deployment
5. **Path issues** - Absolute paths required for all parameters
6. **Build directory space** - Disk space in /tmp
7. **Git clone failures** - URL format, authentication, network
8. **File copy issues** - Destination permissions, disk space

## Version History Notes
- **v2.0**: Complete rewrite with 4 parameters, fresh clone approach
  - Added `git_url` and `build_dir` parameters
  - Renamed `REPO_DIR` to `DEST_DIR`
  - Unified deployment process (no separate root/sub-site logic)
  - Fresh clone instead of git pull
  - Build directory cleanup on each run
  
- **v1.0**: Original design
  - 2 parameters: `repo_dir` and `sub-site`
  - Root used temp directory with git pull
  - Sub-site used direct git pull
  - Different code paths for root vs sub-site

## Migration Notes from v1.0 to v2.0

### Breaking Changes
1. **Parameter count** - Changed from 2 to 4 parameters
2. **Git URL required** - Must explicitly provide repository URL
3. **Build directory required** - Must specify build/workspace location
4. **No git pull** - Always performs fresh clone
5. **Destination not a Git repo** - Destination directory doesn't need `.git`

### What Users Need to Update
1. **All cron jobs** - Add git_url and build_dir parameters
2. **Destination directories** - Can remove `.git` directories (optional)
3. **Documentation references** - Update any scripts that call deploy-site.sh

### Advantages of v2.0
- More explicit configuration (all parameters visible)
- Always deploys latest code (fresh clone)
- Simpler logic (single code path)
- Build directory enables CI/CD patterns
- Destination never needs to be Git repository

---

**To resume working on this project**: Read this file first, then examine deploy-site.sh and README.md to understand current implementation details.