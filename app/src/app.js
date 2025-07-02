import express from "express";
const app = express();

app.get("/health", (_, res) => res.json({ ok: true }));
app.get("/version", (_, res) =>
    res.json({ version: process.env.APP_VERSION || "dev" })
);

app.listen(process.env.PORT ?? 3000, () =>
    console.log(
        `[${process.env.LOG_LEVEL ?? "info"}] Ready on ${
            process.env.PORT ?? 3000
        } – greeting: ${process.env.GREETING_MESSAGE ?? "Hello"}`
    )
);
export default app;