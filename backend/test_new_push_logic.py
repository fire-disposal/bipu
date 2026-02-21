scription_table.c.user_id).where(
        subscription_table.c.user_id == user.id,
        subscription_table.c.service_account_id == service.id
    )
    existing = db.execute(stmt).first()

    if existing:
        print(f"用户已订阅服务号: {service.name