@{
    Projects = @{

        "ReachX-AI" = @{
            Root = "F:\ReachX-AI"

            DevCommands = @(
                "python -m pip install --upgrade pip",
                # This will now be skipped safely if requirements.txt is missing
                "python -m pip install -r requirements.txt"
            )

            # Adjust later if you actually use Docker for ReachX,
            # for now we'll leave deployment commands empty.
            DeployCommands = @(
                # e.g. "docker compose up -d"
            )
        }

        "AOGRL-Website" = @{
            Root = "C:\Users\ICL  ZAMBIA\Desktop\AOGRL-Website\aogrl-v3-updated"

            # For a Vite/Node site: install + build is enough for CI/verification
            DevCommands = @(
                "npm install",
                "npm run build"
            )

            # Production deploy is via Vercel; no local 'start' needed here.
            DeployCommands = @(
                # No local deploy step. This script will just log "Nothing to do."
            )
        }

        "Board-LLM" = @{
            Root = "F:\AION-ZERO\board-llm"

            DevCommands = @(
                "npm install"
            )

            DeployCommands = @(
                "node .\board-llm-server.cjs"
            )
        }
    }
}
