# API_CONTRACT.md — عقد API مبدئي (تخطيطي، بدون تنفيذ) — حجوزاتي

> يُستخدم كمرجع لبناء Backend لاحقًا (Phase 19). لا Backend فعلي حاليًا.

## Auth
| Endpoint | Purpose | Request | Response | Errors | Auth Required |
|---|---|---|---|---|---|
| POST /auth/register | تسجيل مستخدم جديد | name, email/phone, password | User + token | 400 بيانات ناقصة، 409 مستخدم موجود | لا |
| POST /auth/login | تسجيل الدخول | email/phone, password | User + token | 401 بيانات خاطئة | لا |
| POST /auth/logout | تسجيل الخروج | token | 200 | 401 | نعم |

## Hotels
| Endpoint | Purpose | Request | Response | Errors | Auth |
|---|---|---|---|---|---|
| GET /hotels/{id} | تفاصيل فندق | hotelId | Hotel كامل + Rooms | 404 | لا |
| GET /governorates | قائمة المحافظات | — | List\<Governorate> | — | لا |

## Search
| Endpoint | Purpose | Request | Response | Errors | Auth |
|---|---|---|---|---|---|
| POST /search/hotels | بحث فنادق حسب معايير | SearchCriteria | List\<SearchResult> | 400 معايير غير صالحة | لا |

## Rooms
| Endpoint | Purpose | Request | Response | Errors | Auth |
|---|---|---|---|---|---|
| GET /hotels/{id}/rooms | غرف فندق ضمن تواريخ | hotelId, checkIn, checkOut | List\<Room> | 404 | لا |

## Availability
| Endpoint | Purpose | Request | Response | Errors | Auth |
|---|---|---|---|---|---|
| GET /rooms/{id}/availability | توفر غرفة ضمن فترة | roomId, checkIn, checkOut | List\<RoomAvailability> | 404 | لا |

## Bookings
| Endpoint | Purpose | Request | Response | Errors | Auth |
|---|---|---|---|---|---|
| POST /bookings | إنشاء حجز (تأكيد) | BookingDraft كامل | Booking + qrCodeData | 400 بيانات ناقصة، 409 الغرفة لم تعد متاحة | نعم |
| GET /bookings | حجوزات المستخدم | userId (من التوكن), status? | List\<Booking> | 401 | نعم |
| GET /bookings/{id} | تفاصيل حجز | bookingId | Booking | 404 | نعم |
| PATCH /bookings/{id}/cancel | إلغاء حجز | bookingId | Booking (status=cancelled) | 404, 409 لا يمكن الإلغاء | نعم |

## Favorites
| Endpoint | Purpose | Request | Response | Errors | Auth |
|---|---|---|---|---|---|
| GET /favorites | قائمة المفضلة | — | List\<Hotel> | 401 | نعم |
| POST /favorites/{hotelId} | إضافة للمفضلة | hotelId | 201 | 404 | نعم |
| DELETE /favorites/{hotelId} | إزالة من المفضلة | hotelId | 200 | 404 | نعم |

## Destinations
| Endpoint | Purpose | Request | Response | Errors | Auth |
|---|---|---|---|---|---|
| GET /destinations | قائمة وجهات اكتشف العراق | governorateId? | List\<Destination> | — | لا |
| GET /destinations/{id} | تفاصيل وجهة + فنادق قريبة | destinationId | Destination + List\<Hotel> | 404 | لا |

## User Profile
| Endpoint | Purpose | Request | Response | Errors | Auth |
|---|---|---|---|---|---|
| GET /profile | بيانات المستخدم الحالي | — | User | 401 | نعم |
| PATCH /profile | تعديل بيانات المستخدم | حقول جزئية | User محدَّث | 400, 401 | نعم |

## Notifications (مستقبلي)
| Endpoint | Purpose | Request | Response | Errors | Auth |
|---|---|---|---|---|---|
| GET /notifications | قائمة إشعارات المستخدم | — | List\<Notification> | 401 | نعم |
| PATCH /notifications/{id}/read | تعليم كمقروء | notificationId | 200 | 404 | نعم |

## Hotel Partner (مستقبلي)
| Endpoint | Purpose | Request | Response | Errors | Auth |
|---|---|---|---|---|---|
| GET /partner/hotel | بيانات فندق المدير | — | Hotel كامل | 401, 403 | نعم (role=hotelManager) |
| PATCH /partner/hotel | تعديل بيانات الفندق | حقول جزئية | Hotel محدَّث | 400 | نعم |
| POST /partner/rooms | إضافة غرفة | Room | Room منشأ | 400 | نعم |
| PATCH /partner/rooms/{id} | تعديل غرفة | حقول جزئية | Room محدَّث | 404 | نعم |
| GET /partner/bookings | حجوزات الفندق | status? | List\<Booking> | 401, 403 | نعم |

## Admin (مستقبلي)
| Endpoint | Purpose | Request | Response | Errors | Auth |
|---|---|---|---|---|---|
| GET /admin/hotels/pending | فنادق بانتظار الموافقة | — | List\<Hotel> | 403 | نعم (role=admin) |
| PATCH /admin/hotels/{id}/approve | قبول فندق | hotelId | Hotel محدَّث | 404 | نعم |
| PATCH /admin/hotels/{id}/reject | رفض فندق | hotelId, reason | Hotel محدَّث | 404 | نعم |
| GET /admin/users | إدارة المستخدمين | — | List\<User> | 403 | نعم |
| GET /admin/stats | إحصائيات عامة | — | تقرير إحصائي | 403 | نعم |

## ملاحظات عامة
- كل الاستجابات تتبع شكلًا موحّدًا: `{ data, error, meta }`.
- المصادقة عبر Bearer Token في الترويسة `Authorization`.
- كل الأخطاء تعيد `{ code, message }` قابلة للترجمة في الواجهة.
