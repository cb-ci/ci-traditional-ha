
---

## 🔹 Step 1. Update the image

First, pull the latest image for the service you want to upgrade:

```bash
docker compose pull service2
```

(or use a specific tag, e.g. `myrepo/service2:2.1.0` in your `docker-compose.yml`).

---

## 🔹 Step 2. Restart only that service

Bring down and recreate **just that service**:

```bash
docker compose up -d --no-deps service2
```

* `-d` → runs in background.
* `--no-deps` → prevents dependent services from being restarted.
* Only `service2` is recreated with the new image; other services remain online.

---

## 🔹 Step 3. Verify

Check that the container is running the new image:

```bash
docker compose ps service2
```

Or inspect the container:

```bash
docker inspect service2
```

---

## 🔹 (Optional) Rollback

If something goes wrong:

1. Switch back to the previous image tag in `docker-compose.yml`.
2. Run again:

   ```bash
   docker compose up -d --no-deps service2
   ```

---

✅ This way, **only `service2` is upgraded** and the rest of your stack stays online.

---
