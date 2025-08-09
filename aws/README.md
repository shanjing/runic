# AWS Authentication

This directory contains scripts and configuration for AWS authentication with MFA and role assumption.

## 🔐 Authentication Setup

### Prerequisites

1. **AWS CLI installed**: Make sure you have AWS CLI v2 installed
2. **AWS Profile configured**: Ensure you have the `shaniac` profile configured in `~/.aws/credentials`
3. **jq installed**: Required for parsing JSON responses

### AWS Profile Configuration

Before using the authentication script, ensure your AWS profile is configured:

```bash
# Configure your AWS profile
aws configure --profile shaniac

# Enter your credentials when prompted:
# AWS Access Key ID: [your-access-key]
# AWS Secret Access Key: [your-secret-key]
# Default region: [your-region]
# Default output format: json
```

## 🚀 Using the Authentication Script

### Quick Start

1. **Make the script executable**:
   ```bash
   chmod +x aws/assume-role.sh
   ```

2. **Run the authentication script**:
   ```bash
   source aws/assume-role.sh
   ```

3. **Enter your MFA token** when prompted (6-digit code from your authenticator app)

### What the Script Does

The `assume-role.sh` script:

- Assumes the `admin-role` IAM role using your MFA device
- Creates temporary credentials valid for 4 hours (14400 seconds)
- Sets environment variables for AWS CLI usage
- Verifies the authentication by calling `aws sts get-caller-identity`

### Environment Variables Set

After running the script, these environment variables are set:

```bash
export AWS_ACCESS_KEY_ID="[temporary-access-key]"
export AWS_SECRET_ACCESS_KEY="[temporary-secret-key]"
export AWS_SESSION_TOKEN="[temporary-session-token]"
```

## 🔧 Usage with Terraform

Once authenticated, you can use Terraform with the temporary credentials:

```bash
# Navigate to your Terraform directory
cd terraform/envs/dev

# Initialize and plan
terraform init
terraform plan

# Apply changes
terraform apply
```

## 🔧 Usage with AWS CLI

After authentication, all AWS CLI commands will use the temporary credentials:

```bash
# List S3 buckets
aws s3 ls

# Check current identity
aws sts get-caller-identity

# List EC2 instances
aws ec2 describe-instances
```

## ⚠️ Important Notes

### Security
- **Temporary Credentials**: The script creates temporary credentials that expire after 4 hours
- **MFA Required**: You must provide a valid MFA token each time you run the script
- **Role Assumption**: The script assumes the `admin-role` which should have appropriate permissions

### Session Management
- **Re-authentication**: You'll need to run the script again when credentials expire
- **Multiple Sessions**: You can run the script multiple times for different sessions
- **Environment Variables**: The script overwrites existing AWS environment variables

### Troubleshooting

#### Common Issues

1. **"Invalid MFA token"**:
   - Ensure you're using the correct 6-digit code from your authenticator app
   - Check that your MFA device ARN is correct

2. **"Access denied"**:
   - Verify your base profile has permission to assume the role
   - Check that the role ARN is correct

3. **"jq command not found"**:
   - Install jq: `brew install jq` (macOS) or `sudo apt-get install jq` (Ubuntu)

4. **"Profile not found"**:
   - Ensure the `shaniac` profile is configured in `~/.aws/credentials`

#### Verification Commands

```bash
# Check if profile exists
aws configure list-profiles

# Test profile access
aws sts get-caller-identity --profile shaniac

# Check MFA device
aws iam list-mfa-devices --profile shaniac
```

## 📋 Configuration Details

### Role ARN
- **Role**: `arn:aws:iam::403692606562:role/admin-role`
- **Account**: `403692606562`
- **Session Name**: `shaniacSession`

### MFA Device
- **Device ARN**: `arn:aws:iam::403692606562:mfa/shaniac`
- **Type**: Virtual MFA device (authenticator app)

### Session Duration
- **Duration**: 4 hours (14400 seconds)
- **Maximum**: 12 hours (43200 seconds) for role assumption

---

**Note**: Keep your AWS credentials secure and never commit them to version control. The script uses temporary credentials for enhanced security.
