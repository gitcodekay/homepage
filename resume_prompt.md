# Git Auto-Deploy Script - Context Resume

## Project Overview
This is a bash-based Git deployment solution for Linux servers that operates **without deployment agents**. It uses cron jobs and flag files to provide manual deployment control with automatic locking after each deployment.

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
deploy-site.sh <repo_dir> <sub-site>
```
- `repo_dir`: Base directory (e.g., `/var/www/html`)
- `sub-site`: Either `-` for root or sub-site folder name

### Two Deployment Modes

**1. Root Deployment (sub-site = "-")**
- Purpose: Safely deploy to directories with non-Git files
- Process:
  1. Pull to temp directory (`/tmp/main`)
  2. Copy files one-by-one to `repo_dir`
  3. Preserves non-Git managed files in destination
- Flag location: `repo_dir/hold_deploy.txt`

**2. Sub-Site Deployment (sub-site = folder name)**
- Purpose: Fast deployment for Git-only directories
- Process: Direct `git pull` in `repo_dir/sub-site`
- Flag location: `repo_dir/sub-site/hold_deploy.txt`
- Validates sub-site directory exists before attempting deployment

### Script Logic Flow
1. Check parameters provided
2. Determine full repo path based on sub-site parameter
3. Check if `hold_deploy.txt` exists → if yes, silent exit (blocked)
4. If no flag, proceed with deployment:
   - Root: temp pull + file copy
   - Sub-site: direct git pull
5. Create `hold_deploy.txt` to block future deployments
6. Log all actions with format: `$(date) [$SUB_SITE] : message`

### Logging
- File: `/var/log/deploy-site.log`
- Format: `Sat Nov  8 14:23:15 EST 2025 [sub-site] : message`
- Includes: deployment start, errors, completion, flag creation

## Cron Integration
- Runs script at regular intervals (typically `*/5 * * * *`)
- Each site/sub-site has independent cron entry
- Can schedule multiple sites with different frequencies

Example:
```cron
*/5 * * * * /usr/local/bin/deploy-site.sh /var/www/html -
*/5 * * * * /usr/local/bin/deploy-site.sh /var/www/html myapp
```

## Important Design Decisions

### Why flag-based control?
- No webhooks or external agents needed
- Manual approval prevents accidental deployments
- Simple to understand and troubleshoot
- Works with any Git provider

### Why temp directory for root?
- Prevents deletion of non-Git files (configs, logs, uploads)
- Safer for shared directories
- Avoids Git working directory conflicts

### Why auto-lock after deployment?
- Prevents continuous deployments from eating resources
- Forces deliberate deployment approval
- Easy to track when deployments occurred

### Why separate flags per site?
- Independent deployment control
- Can deploy one site without affecting others
- Clearer logging and debugging

## Common Update Scenarios

### Adding new feature to script
1. Review script logic flow above
2. Maintain flag check at start
3. Preserve two deployment modes
4. Update log format to include relevant info
5. Test with both `-` and sub-site parameters
6. Update README with new feature documentation

### Changing flag behavior
1. Update flag file name in `FLAG_NAME` variable
2. Update all references in script (check, create)
3. Update README sections: "Deployment Control", "How It Works"
4. Update troubleshooting section if needed

### Modifying deployment logic
- Root mode: Update temp directory operations
- Sub-site mode: Update git pull section
- Both: Update error handling and logging

### Adding parameters
1. Update parameter validation section
2. Document in README "Usage" and "Script Syntax"
3. Update all example commands
4. Add to troubleshooting if complex

## File Structure Expected
```
project.zip
├── deploy-site.sh           # Main deployment script
├── README.md                # Complete documentation
└── CONTEXT_RESUME.md        # This file
```

## Quick Reference: What Goes Where

**In deploy-site.sh:**
- Deployment logic
- Flag checking
- Git operations
- Logging
- Error handling

**In README.md:**
- Installation steps
- Usage examples
- Cron configuration
- Enable/block deployment instructions
- Troubleshooting
- Security considerations
- Advanced configurations

**This file (CONTEXT_RESUME.md):**
- High-level architecture
- Design decisions
- Update guidance
- Quick reference

## Testing Checklist for Updates
- [ ] Test root deployment with `-` parameter
- [ ] Test sub-site deployment with folder name
- [ ] Verify flag blocks deployment when present
- [ ] Verify flag removed allows deployment
- [ ] Verify flag auto-creates after deployment
- [ ] Check log entries format correctly
- [ ] Test with non-existent sub-site (should error)
- [ ] Verify temp directory cleanup (root mode)
- [ ] Test with missing parameters
- [ ] Verify cron execution

## Common User Issues (for README updates)
1. **Permissions** - Script, web directory, Git access
2. **Git auth** - SSH keys, HTTPS credentials
3. **Cron not running** - Service status, syntax errors
4. **Flag confusion** - Presence blocks vs allows deployment
5. **Path issues** - Absolute paths required

## Update Instructions for AI Assistant
When user provides zip file with these files and requests updates:

1. **Read all three files** to understand current state
2. **Identify what changed** - script logic, flag behavior, parameters?
3. **Apply changes consistently** across script and README
4. **Maintain design patterns**: flag-based control, dual deployment modes
5. **Update relevant sections**: 
   - Script: Update code + comments
   - README: Update affected sections (usage, troubleshooting, etc.)
   - This file: Update if architecture changes
6. **Preserve working features** unless explicitly asked to change
7. **Test logic mentally** against checklist above

## Version History Notes
- Original design: Cron-based with flag control
- Flag name: `hold_deploy.txt` (was `deploy_flag_on.txt`)
- Log format: `$(date) [$SUB_SITE] : message`
- Temp directory: `/tmp/main` for root deployments
- Parameters: `<repo_dir> <sub-site>` (sub-site can be `-`)

---

**To resume working on this project**: Read this file first, then examine deploy-site.sh and README.md to understand current implementation details.