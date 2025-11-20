# Secure RDP Access via Tailscale using GitHub Actions

This project provides a GitHub Actions workflow to create a secure Remote Desktop (RDP) session to a GitHub-hosted runner. Access is secured using [Tailscale](https://tailscale.com/), which creates a private network and avoids exposing the RDP port to the public internet.

## Features

- **Secure Access**: RDP port is not exposed to the public internet. A firewall rule is created to only allow connections over the Tailscale interface.
- **On-Demand**: Spin up an RDP session whenever you need it by manually triggering the workflow.
- **Automatic Cleanup**: All resources (RDP user, firewall rules, Tailscale connection) are automatically removed at the end of the session or if the workflow is cancelled.
- **Configurable**: Choose the Windows version, Tailscale version, and session duration when you run the workflow.
- **Robust**: Includes retry logic with exponential backoff for network operations.
- **Secure Credentials**: The generated RDP password is automatically masked in logs and exposed as a secure workflow output.

## How to Use

1.  **Add Tailscale Auth Key to Secrets**:
    - Go to your Tailscale Admin Console and generate an **Auth Key**. It's recommended to use an ephemeral, one-off key.
    - In your GitHub repository, go to `Settings` > `Secrets and variables` > `Actions`.
    - Create a new repository secret named `TAILSCALE_AUTH_KEY` and paste your Tailscale auth key.

2.  **Run the Workflow**:
    - Go to the `Actions` tab in your GitHub repository.
    - Select the `RDP` workflow from the list.
    - Click the `Run workflow` dropdown.
    - (Optional) Customize the input parameters:
        - **Windows version**: `windows-latest`, `windows-2022`, or `windows-2019`.
        - **Tailscale version**: The version of Tailscale to install (e.g., `1.82.0`).
        - **Session timeout**: How long the session should remain active.
    - Click `Run workflow`.

3.  **Connect to the RDP Session**:
    - Once the workflow starts, the `Display Connection Details` step will output the Tailscale IP Address, Username, and Password.
    - Use any RDP client to connect to the machine using these credentials.
    - **Important**: The workflow must remain running to maintain the connection.

4.  **Terminate the Session**:
    - To end the RDP session, simply **cancel the workflow** in the GitHub Actions UI. The cleanup job will automatically run to remove the user and disconnect Tailscale.

## Project Structure

```
.
├── .github/
│   └── workflows/
│       └── rdp.yml       # The main GitHub Actions workflow
├── scripts/
│   ├── Cleanup.ps1       # Cleans up all resources
│   ├── Configure-RDP.ps1 # Configures RDP and firewall
│   ├── Connect-Tailscale.ps1 # Connects to Tailscale
│   ├── Create-RDPUser.ps1  # Creates the temporary RDP user
│   └── Install-Tailscale.ps1 # Downloads and installs Tailscale
└── README.md             # This file
```
