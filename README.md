# GitLab Cloud Docker

Self-hosted GitLab Enterprise Edition (EE) using Docker Compose. Works on AWS EC2, DigitalOcean, and other cloud providers. Optimized for 4GB RAM instances.

## 🚀 Features

- **GitLab Enterprise Edition Nightly** - Latest features and bleeding edge updates
- **Docker-based deployment** - Simple setup
- **Memory optimized** - Runs well on 4GB RAM
- **Environment-based configuration** - Easy IP and password management
- **Token creation script** - Bypass web UI bugs
- **Cloud deployment** - Works on AWS EC2, DigitalOcean, etc.
- **Custom ports** - Uses port 8929/2222 to avoid conflicts

## 📋 Prerequisites

- Docker 20.10+
- Docker Compose 1.29+ (or `docker-compose` standalone)
- **4GB RAM** (2GB works but slow as hell)
- 20GB disk space minimum
- Ubuntu 22.04 or similar Linux distribution

## 🛠️ Quick Start

### 1. Clone or Download

```bash
git clone https://github.com/zinx110/gitlab-cloud-docker.git
cd gitlab-cloud-docker
```

### 2. Configure Environment Variables

Edit the `.env` file:

```bash
nano .env
```

Set your values:
```env
# Initial root password for first-time setup
INITIAL_PASSWORD=YourSecurePassword123!

# Your server's public IP address (leave empty for localhost)
EXTERNAL_IP=54.123.45.67
```

### 3. Start GitLab

```bash
docker-compose up -d
```

### 4. Access GitLab

Wait 3-5 minutes for GitLab to initialize, then access:

- **URL:** `http://YOUR-IP:8929`
- **Username:** `root`
- **Password:** (from your `.env` file)

## 📁 Project Structure

```
.
├── docker-compose.yml       # Main Docker Compose configuration
├── .env                     # Environment variables (passwords, IPs)
├── create-token.sh          # Helper script for creating API tokens
├── README.md                # This file
├── config/                  # GitLab configuration (auto-generated)
├── logs/                    # GitLab logs (auto-generated)
└── data/                    # GitLab data (auto-generated)
```

## ⚙️ Configuration

### Ports

- **8929** - GitLab Web UI (HTTP)
- **2222** - GitLab SSH (Git operations)

### Memory Optimization

The configuration is optimized for 4GB RAM:
- 4 Puma workers
- 20 Sidekiq concurrency
- Prometheus monitoring enabled
- 512MB PostgreSQL buffers

### Docker Compose Configuration

Key settings in `docker-compose.yml`:
```yaml
puma['worker_processes'] = 4
sidekiq['max_concurrency'] = 20
postgresql['shared_buffers'] = "512MB"
prometheus_monitoring['enable'] = true
```

## 🔧 Usage

### Start GitLab

```bash
docker-compose up -d
```

### Stop GitLab

```bash
docker-compose down
```

### View Logs

```bash
docker logs -f gitlab
```

### Check Status

```bash
docker ps
```

### Restart GitLab

```bash
docker restart gitlab
```

### Create Personal Access Token

If the web UI has issues creating tokens:

```bash
./create-token.sh "my-token-name" 365
```

Arguments:
- `my-token-name` - Token name (optional)
- `365` - Days until expiry (optional, default: 365)

## 🌐 Cloud Deployment

### AWS EC2 Setup

1. **Launch Instance:**
   - Type: **t3a.medium** (4GB RAM, 2 vCPU)
   - Use **Spot instance** for 70% discount (~$4 for 2 weeks)
   - OS: Ubuntu 22.04 LTS
   - Storage: 20GB minimum
   - Security Groups: 22, 8929, 2222

2. **Get Elastic IP (Optional but Recommended):**
   - AWS Console → EC2 → Elastic IPs → Allocate
   - Associate with your instance
   - This gives you a permanent IP that doesn't change on restart

3. **Install Docker:**
   ```bash
   sudo apt update
   sudo apt install -y docker.io docker-compose
   sudo systemctl start docker
   sudo usermod -aG docker ubuntu
   exit  # Log out and back in
   ```

4. **Upload files and configure `.env` with your Elastic IP**

5. **Start GitLab:**
   ```bash
   docker-compose up -d
   # Wait 3-5 minutes for startup
   docker logs -f gitlab
   ```

### DigitalOcean / Other Providers

Same steps as AWS - just adjust security group/firewall rules for your provider.

## 🔐 Security Considerations

- ⚠️ **Change default password** after first login
- 🔒 **Add HTTPS** if you care (need SSL certificate)
- 🛡️ **Restrict SSH access** to your IP only in security group
- 🔑 **Never commit `.env`** to git
- 💾 **Backup `data/` directory** if you have important stuff

## 🐛 Troubleshooting

### GitLab Won't Start

```bash
# Check logs
docker logs gitlab

# Check available memory
free -h

# Ensure swap is enabled
swapon --show
```

### Getting 502 Bad Gateway

**This means nginx is working but Puma (Rails backend) isn't responding.**

```bash
# Check if all services are running
docker exec gitlab gitlab-ctl status

# Reconfigure GitLab with correct external_url
docker exec gitlab gitlab-ctl reconfigure

# Restart Puma
docker exec gitlab gitlab-ctl restart puma

# If still broken, nuclear option:
docker-compose down -v
sudo rm -rf config/ logs/ data/
docker-compose up -d
```

### Can't Access from Browser (But localhost Works)

- Check AWS Security Group has port **8929** open to **0.0.0.0/0**
- Verify `EXTERNAL_IP` in `.env` matches your server's public IP
- Make sure you're using **http://** not **https://**
- Test: `curl -I http://YOUR-IP:8929` from the server

### Slow Performance or Out of Memory

**Solution:** Use a bigger instance. 2GB is too small.

```bash
# Check memory usage
free -h
docker stats gitlab --no-stream

# If using 2GB, upgrade to 4GB instance (t3a.medium)
```

### Token Creation Fails in Web UI

Use the provided script:
```bash
./create-token.sh "my-token"
```

This is a known issue in nightly builds and bypasses the web UI.

### Permission Denied Errors

```bash
# Fix Docker permissions
sudo usermod -aG docker $USER
exit
# Log back in
```

## 📊 System Requirements

| Use Case | RAM | CPU | Storage | AWS Instance |
|----------|-----|-----|---------|--------------|
| **Testing (2-4 users)** | 4GB | 2 vCPU | 20GB | t3a.medium |
| **Small team (5-10)** | 8GB | 2 vCPU | 50GB | t3a.large |
| **Medium team (10-50)** | 16GB | 4 vCPU | 100GB | t3a.xlarge |

**Note:** 2GB technically works but is slow as hell. Just use 4GB.

## 🔄 Upgrade GitLab

```bash
# Pull latest image
docker-compose pull

# Restart with new image
docker-compose up -d
```

**Note:** Always backup before upgrading!

## 💾 Backup & Restore

### Backup

```bash
# Stop GitLab
docker-compose down

# Backup data directory
tar -czf gitlab-backup-$(date +%Y%m%d).tar.gz data/ config/

# Restart GitLab
docker-compose up -d
```

### Restore

```bash
# Stop GitLab
docker-compose down

# Extract backup
tar -xzf gitlab-backup-YYYYMMDD.tar.gz

# Restart GitLab
docker-compose up -d
```

## 🔗 Useful Commands

```bash
# Enter GitLab container
docker exec -it gitlab bash

# Run GitLab Rails console
docker exec -it gitlab gitlab-rails console

# Check GitLab version
docker exec gitlab cat /opt/gitlab/version-manifest.txt

# Reconfigure GitLab
docker exec gitlab gitlab-ctl reconfigure

# Check all GitLab services
docker exec gitlab gitlab-ctl status
```

## 📚 Resources

- [GitLab Documentation](https://docs.gitlab.com/)
- [GitLab Docker Installation](https://docs.gitlab.com/ee/install/docker/)
- [GitLab API Documentation](https://docs.gitlab.com/ee/api/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

## ⚠️ Notes

- This uses GitLab EE **nightly builds** - expect bugs and breaking changes
- All EE features work without a license (you'll just see an "unlicensed" banner)
- Good for testing, learning, small teams, and personal projects

## 💬 Support

- **Issues:** Open an issue in this repository
- **GitLab Forum:** https://forum.gitlab.com/
- **Stack Overflow:** Tag questions with `gitlab`

## 📈 Version

- **GitLab:** EE Nightly (18.5.0+)
- **Docker Compose:** 1.29+
- **Tested on:** Ubuntu 22.04, Amazon Linux 2023

---

**GitLab Cloud Docker** - Simple self-hosted GitLab setup for cloud deployments
