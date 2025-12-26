# SMS Marketing System - AION-ZERO Integration

## Overview
Bulk SMS marketing system integrated into TITAN OS, enabling cost-effective SMS campaigns using an Android phone as an SMS gateway.

## Features
- ✅ Compose and send bulk SMS campaigns
- ✅ Contact management with CSV import
- ✅ Campaign tracking and analytics
- ✅ Android phone SMS gateway integration
- ✅ Delivery status monitoring
- ✅ Message templates
- ✅ Opt-in/opt-out management

## Quick Start (30 Minutes)

### Step 1: Run Database Migration

1. Go to Supabase Dashboard: https://supabase.com/dashboard
2. Select your AION-ZERO project
3. Click **SQL Editor**
4. Open file: `F:\AION-ZERO\sql\sms_marketing_migration.sql`
5. Copy all SQL and paste into editor
6. Click **Run**
7. Verify: You should see 5 new tables created

**Tables Created**:
- `sms_campaigns` - Campaign management
- `sms_messages` - Individual message tracking
- `sms_contacts` - Contact database
- `sms_templates` - Message templates
- `sms_gateway_config` - Gateway settings

---

### Step 2: Set Up Android Phone

#### Option A: SMS Gateway API (Recommended)

**Download App**:
1. On Android phone, open Play Store
2. Search: "SMS Gateway API"
3. Install: [SMS Gateway for Android](https://play.google.com/store/apps/details?id=com.smsgateway)
4. Open app and create account

**Configure**:
1. Grant SMS permissions
2. Go to Settings → API
3. Copy your:
   - API URL (e.g., `https://smsgateway.me/api/v4`)
   - API Key
   - Device ID

#### Option B: Alternative Apps

**Other Options**:
- **SMS Forwarder** - Free, open source
- **Tasker + AutoRemote** - Advanced automation
- **HTTP SMS Gateway** - Self-hosted

---

### Step 3: Configure Gateway in TITAN OS

1. Open TITAN OS: http://localhost:5000 (or your Citadel URL)
2. Click **SMS** tab in navigation
3. Go to **Gateway Settings** tab
4. Enter your credentials:
   - API URL
   - API Key
   - Device ID
5. Click **Save Configuration**

---

### Step 4: Import Contacts

#### Create CSV File

Format: `phone,name,email,tags`

Example `contacts.csv`:
```csv
phone,name,email,tags
+260971234567,John Doe,john@example.com,customer;vip
+260977654321,Jane Smith,jane@example.com,customer
+260965555555,Bob Wilson,bob@example.com,prospect
```

**Notes**:
- Phone numbers must include country code (+260 for Zambia)
- Tags are semicolon-separated
- Name and email are optional

#### Import Process

1. Go to **Contacts** tab
2. Click **Import CSV**
3. Select your CSV file
4. Verify contacts imported successfully

---

### Step 5: Send Your First Campaign

1. Go to **Compose Campaign** tab
2. Enter campaign name: "Test Campaign"
3. Write message (max 160 characters)
4. Select recipients from the list
5. Click **Send Campaign**
6. Monitor delivery in **Campaign History** tab

---

## File Structure

```
F:\AION-ZERO\
├── citadel\
│   └── static\
│       ├── index.html              # Main TITAN OS (SMS tab added)
│       └── sms_marketing.html      # SMS Marketing interface
├── sql\
│   └── sms_marketing_migration.sql # Database schema
└── docs\
    └── SMS_MARKETING_GUIDE.md      # This file
```

---

## Integration Points

### TITAN OS Navigation
- New **SMS** tab added to main navigation bar
- Accessible from any TITAN OS page
- Embedded as iframe for seamless integration

### Database Tables
All tables use Supabase with Row Level Security (RLS) enabled:
- Authenticated users have full access
- Data isolated per project

### API Endpoints (Future)
Backend API endpoints can be added to `citadel/server.py`:
- `POST /api/sms/send` - Send single SMS
- `POST /api/sms/campaign` - Create campaign
- `GET /api/sms/campaigns` - List campaigns
- `POST /api/sms/contacts/import` - Import contacts

---

## Cost Analysis

### Using Android Phone + SIM Card

**Monthly Costs**:
- SIM card with unlimited SMS: ~$5-10
- SMS Gateway app (pro): ~$5
- **Total**: ~$10-15/month

**vs Commercial Services**:
- Twilio: $0.04 per SMS
- Africa's Talking: $0.02 per SMS
- 1000 SMS/month = $20-40

**Savings**: 50-75% cheaper!

---

## Best Practices

### Message Content
- Keep under 160 characters
- Include opt-out instructions
- Personalize when possible
- Clear call-to-action

### Sending Schedule
- Avoid late night (10pm-8am)
- Best times: 10am-12pm, 2pm-5pm
- Test small batch first
- Monitor delivery rates

### Contact Management
- Regular list cleaning
- Honor opt-outs immediately
- Segment by tags
- Track engagement

---

## Troubleshooting

### Messages Not Sending

**Check**:
1. Android phone is connected to WiFi/data
2. SMS Gateway app is running
3. API credentials are correct in settings
4. Phone has SMS permission
5. SIM card has credit/plan

### "Gateway Not Configured" Error

**Fix**:
1. Verify gateway settings in SMS tab
2. Check API credentials
3. Test with single SMS first

### Slow Sending

**Normal**: Rate limited to 1 SMS/second to avoid spam detection
**Adjust**: Modify rate limit in gateway config

---

## Advanced Features (Coming Soon)

- [ ] Message scheduling
- [ ] A/B testing campaigns
- [ ] Automated triggers (order placed, shipped, etc.)
- [ ] SMS analytics dashboard
- [ ] Integration with OKASINA orders
- [ ] WhatsApp Business API support
- [ ] Multi-gateway support (failover)

---

## Security Notes

- API keys stored in Supabase (encrypted)
- RLS policies enforce access control
- Phone numbers validated before sending
- Opt-out tracking for compliance
- Rate limiting to prevent abuse

---

## Support

**Issues?**
- Check phone app logs
- Verify API credentials
- Test with single SMS first
- Check Supabase logs

**Need Help?**
- SMS Gateway API docs: https://smsgateway.me/docs
- AION-ZERO support: Contact Omran

---

**You're ready to send bulk SMS from TITAN OS!** 🚀

## Next Steps

1. ✅ Run database migration
2. ✅ Set up Android phone
3. ✅ Configure gateway settings
4. ✅ Import test contacts
5. ✅ Send test campaign
6. ⏳ Integrate with OKASINA orders
7. ⏳ Create message templates
8. ⏳ Set up automated campaigns
