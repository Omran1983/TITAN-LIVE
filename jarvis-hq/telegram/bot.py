import os
import logging
from dataclasses import dataclass

from telegram import Update
from telegram.ext import Application, CommandHandler, MessageHandler, ContextTypes, filters


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@dataclass
class BotConfig:
    token: str


def load_config() -> BotConfig:
    token = os.getenv("TELEGRAM_BOT_TOKEN", "")
    if not token:
        raise RuntimeError("TELEGRAM_BOT_TOKEN is not set in environment")
    return BotConfig(token=token)


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    await update.message.reply_text("Jarvis HQ at your service. Send a command to enqueue.")


async def handle_text(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    text = (update.message.text or "").strip()
    if not text:
        return

    # TODO: call Control Plane /api/commands and enqueue safely
    logger.info("Received text from %s: %s", update.effective_user.id, text)
    await update.message.reply_text(f"Command received (not yet enqueued): {text}", parse_mode="Markdown")


async def main() -> None:
    cfg = load_config()
    app = Application.builder().token(cfg.token).build()

    app.add_handler(CommandHandler("start", start))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_text))

    logger.info("Starting Telegram bot...")
    await app.run_polling()


if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
