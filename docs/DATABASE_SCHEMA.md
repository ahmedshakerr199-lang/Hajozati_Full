# DATABASE_SCHEMA.md — تخطيط قاعدة بيانات مستقبلية (بدون تنفيذ فعلي) — حجوزاتي

## users
| Column | Type | ملاحظات |
|---|---|---|
| id | PK | |
| name | text | |
| email | text (unique, nullable) | |
| phone | text (unique, nullable) | |
| password_hash | text | |
| preferred_language | enum(ar,en,fa) | |
| role | enum(user, hotel_manager, admin) | |
| created_at | timestamp | |

## governorates
| Column | Type |
|---|---|
| id | PK |
| name_ar | text |
| name_en | text |
| latitude | decimal |
| longitude | decimal |

## hotels
| Column | Type | ملاحظات |
|---|---|---|
| id | PK | |
| governorate_id | FK → governorates.id | |
| name | text | |
| address | text | |
| latitude / longitude | decimal | |
| rating | decimal | |
| description | text | |
| policies | text | |
| status | enum(pending, approved, rejected) | |
| created_at | timestamp | |

## hotel_images
| Column | Type |
|---|---|
| id | PK |
| hotel_id | FK → hotels.id |
| url | text |
| is_cover | boolean |

## hotel_amenities
| Column | Type |
|---|---|
| id | PK |
| hotel_id | FK → hotels.id |
| name | text |
| icon | text |

## rooms
| Column | Type | ملاحظات |
|---|---|---|
| id | PK | |
| hotel_id | FK → hotels.id | |
| name | text | |
| type | enum(single, double, suite, family, ...) | |
| capacity_adults | int | |
| capacity_children | int | |
| beds | int | |
| price | decimal | |
| discount | decimal (nullable) | |
| cancellation_policy | text | |

## room_images
| Column | Type |
|---|---|
| id | PK |
| room_id | FK → rooms.id |
| url | text |

## room_availability
| Column | Type | ملاحظات |
|---|---|---|
| id | PK | |
| room_id | FK → rooms.id | |
| date | date | |
| is_available | boolean | |
| price_override | decimal (nullable) | |

*(فهرس مركّب فريد: room_id + date)*

## bookings
| Column | Type | ملاحظات |
|---|---|---|
| id | PK | Booking Reference |
| user_id | FK → users.id | |
| hotel_id | FK → hotels.id | نسخة مرجعية وقت الحجز |
| room_id | FK → rooms.id | |
| check_in | date | |
| check_out | date | |
| adults | int | |
| children | int | |
| subtotal | decimal | |
| fees | decimal | |
| discount | decimal | |
| total | decimal | |
| status | enum(pending_confirmation, confirmed, upcoming, completed, cancelled) | |
| qr_code_data | text | |
| created_at | timestamp | |

## booking_guests
| Column | Type |
|---|---|
| id | PK |
| booking_id | FK → bookings.id |
| full_name | text |
| phone | text |
| email | text (nullable) |
| notes | text (nullable) |

## favorites
| Column | Type |
|---|---|
| id | PK |
| user_id | FK → users.id |
| hotel_id | FK → hotels.id |
| created_at | timestamp |

*(فهرس مركّب فريد: user_id + hotel_id)*

## destinations
| Column | Type |
|---|---|
| id | PK |
| governorate_id | FK → governorates.id |
| name | text |
| description | text |
| latitude / longitude | decimal |

## destination_nearby_hotels (جدول ربط N—N)
| Column | Type |
|---|---|
| destination_id | FK → destinations.id |
| hotel_id | FK → hotels.id |

## notifications
| Column | Type |
|---|---|
| id | PK |
| user_id | FK → users.id |
| title | text |
| body | text |
| type | enum(booking_confirmed, reminder, offer, system) |
| is_read | boolean |
| created_at | timestamp |

## hotel_managers
| Column | Type |
|---|---|
| id | PK |
| user_id | FK → users.id |
| hotel_id | FK → hotels.id |

## admins
| Column | Type |
|---|---|
| id | PK |
| user_id | FK → users.id |
| permissions | text[] / json |

## العلاقات (Summary)
- `governorates` 1—N `hotels`, `destinations`
- `hotels` 1—N `rooms`, `hotel_images`, `hotel_amenities`
- `rooms` 1—N `room_images`, `room_availability`
- `users` 1—N `bookings`, `favorites`, `notifications`
- `bookings` 1—N `booking_guests`
- `destinations` N—N `hotels` عبر `destination_nearby_hotels`
- `hotel_managers` N—1 `users`, N—1 `hotels`
- `admins` N—1 `users`

> هذا Schema تخطيطي فقط ولن يُنشأ فعليًا قبل Phase 19 (Backend Integration)، وهو متوافق مباشرة مع النماذج الموصوفة في DATA_MODELS.md.
