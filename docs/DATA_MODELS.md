# DATA_MODELS.md — حجوزاتي (Hajozati)

> تخطيط الحقول والعلاقات فقط — بدون Implementation فعلي.

## User
| Field | Type | ملاحظات |
|---|---|---|
| id | String | معرف فريد |
| name | String | |
| email | String? | |
| phone | String? | |
| passwordHash | — | لا يُخزَّن أو يُعرض في الـ Client |
| preferredLanguage | Enum(ar, en, fa) | |
| role | Enum(guest, user, hotelManager, admin) | جاهز للأدوار المستقبلية |
| createdAt | DateTime | |

## Governorate (محافظة)
| Field | Type |
|---|---|
| id | String |
| nameAr | String |
| nameEn | String |
| latitude | double? |
| longitude | double? |

## Hotel
| Field | Type | ملاحظات |
|---|---|---|
| id | String | |
| name | String | |
| governorateId | String | علاقة → Governorate |
| address | String | |
| latitude / longitude | double | لعرض الخريطة والفنادق القريبة |
| rating | double | |
| description | String | |
| amenities | List\<HotelAmenity> | |
| images | List\<HotelImage> | |
| policies | String | |
| minPrice | double | يُحسب من أرخص غرفة متاحة |
| status | Enum(pending, approved, rejected) | جاهز لدور Admin مستقبلًا |

## HotelImage
| Field | Type |
|---|---|
| id | String |
| hotelId | String |
| url | String |
| isCover | bool |

## HotelAmenity
| Field | Type |
|---|---|
| id | String |
| name | String |
| icon | String |

## Room
| Field | Type | ملاحظات |
|---|---|---|
| id | String | |
| hotelId | String | علاقة → Hotel |
| name | String | |
| type | Enum(single, double, suite, family, ...) | |
| images | List\<String> | |
| capacityAdults | int | |
| capacityChildren | int | |
| beds | int | |
| price | double | السعر الأساسي لليلة |
| discount | double? | نسبة أو قيمة خصم |
| amenities | List\<String> | |
| cancellationPolicy | String | |

## RoomAvailability
| Field | Type | ملاحظات |
|---|---|---|
| id | String | |
| roomId | String | |
| date | DateTime | تاريخ محدد |
| isAvailable | bool | |
| priceOverride | double? | سعر خاص بتاريخ معين (عرض/موسم) |

## SearchCriteria
| Field | Type |
|---|---|
| governorateId | String |
| checkIn | DateTime |
| checkOut | DateTime |
| adults | int |
| children | int |

## SearchResult
| Field | Type |
|---|---|
| hotel | Hotel |
| availableRoomsCount | int |
| lowestPrice | double |

## Guest (بيانات النزيل)
| Field | Type |
|---|---|
| fullName | String |
| phone | String |
| email | String? |
| notes | String? |

## BookingDraft (الحالة المركزية أثناء تدفق الحجز)
| Field | Type | ملاحظات |
|---|---|---|
| hotel | Hotel? | |
| room | Room? | |
| checkIn | DateTime? | |
| checkOut | DateTime? | |
| adults | int | |
| children | int | |
| nights | int | يُحسب تلقائيًا من التواريخ |
| guest | Guest? | |
| price | BookingPrice? | |
| bookingId | String? | يُملأ فقط بعد التأكيد |
| status | BookingStatus | يبدأ كـ `draft` |

## BookingPrice
| Field | Type |
|---|---|
| roomPricePerNight | double |
| nights | int |
| subtotal | double |
| fees | double |
| discount | double |
| total | double |

## Booking (الحجز النهائي بعد التأكيد)
| Field | Type | ملاحظات |
|---|---|---|
| id | String | Booking Reference |
| userId | String | |
| hotel | Hotel (snapshot) | نسخة وقت الحجز |
| room | Room (snapshot) | |
| checkIn / checkOut | DateTime | |
| adults / children | int | |
| guest | Guest | |
| price | BookingPrice | |
| status | BookingStatus | |
| qrCodeData | String | يُستخدم لتوليد QR |
| createdAt | DateTime | |

## BookingStatus (Enum)
`draft`, `pendingConfirmation`, `confirmed`, `upcoming`, `completed`, `cancelled`

## Favorite
| Field | Type |
|---|---|
| id | String |
| userId | String |
| hotelId | String |
| createdAt | DateTime |

## Destination (اكتشف العراق)
| Field | Type |
|---|---|
| id | String |
| name | String |
| governorateId | String |
| description | String |
| images | List\<String> |
| latitude / longitude | double |
| nearbyHotelIds | List\<String> |

## Notification (مستقبلي)
| Field | Type |
|---|---|
| id | String |
| userId | String |
| title | String |
| body | String |
| type | Enum(bookingConfirmed, reminder, offer, system) |
| isRead | bool |
| createdAt | DateTime |

## HotelPartner (مستقبلي)
| Field | Type |
|---|---|
| id | String |
| userId | String | علاقة → User (role=hotelManager) |
| hotelId | String | علاقة → Hotel المُدار |

## Admin (مستقبلي)
| Field | Type |
|---|---|
| id | String |
| userId | String | علاقة → User (role=admin) |
| permissions | List\<String> |

## العلاقات الأساسية (Summary)
- Governorate 1—N Hotel
- Hotel 1—N Room
- Hotel 1—N HotelImage, HotelAmenity
- Room 1—N RoomAvailability
- User 1—N Booking, Favorite
- Booking N—1 Hotel (snapshot), N—1 Room (snapshot)
- Destination N—N Hotel (عبر nearbyHotelIds)
- HotelPartner 1—1 Hotel (لكل مدير فندق واحد أو أكثر ضمن نفس الفندق مستقبلًا)
