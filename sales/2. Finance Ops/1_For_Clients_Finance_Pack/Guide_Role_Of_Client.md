# Your Organisation Operations Control Plane (OOCP)

You maintain **ONE Excel File**: `Client_Control_Panel.xlsx`.
It has 4 Tabs. This is your entire operating system.

## TAB 1: Clients (Setup)
List your customers here. TITAN reads this for email addresses.

## TAB 2: Invoices (Finance Ops)
**This is your Cashflow Engine.**
- Add a row & set Status to `APPROVED` -> TITAN sends the invoice.
- Set Status to `PAID` -> TITAN stops chasing.
- Set Status to `DISPUTED` -> TITAN alerts you.

## TAB 3: Payments (Optional)
Log incoming money here. TITAN will match it to the invoice and auto-mark it as PAID.

## TAB 4: Statutory (Compliance)
**This is your Penalty Shield.**
- Toggle `Applies` to **YES**.
- When done, toggle `Action` to **DONE** and paste a link.
- TITAN stops nagging you.
tomatically.

### The Logic: "When X happens, TITAN does Y."

#### A. Launching Invoices (Approval_Status)
| You set this: | TITAN does this: |
| :--- | :--- |
| **Pending** | Nothing. (Draft mode) |
| **Approved** | **Activates.** Generates PDF. Emails Client. Updates `Send_Status` to 'Sent'. |
| **Hold** | **Pauses.** Prevents any sending. |

#### B. Stopping Chasers (Payment_Status)
| You set this: | TITAN does this: |
| :--- | :--- |
| **Unpaid** | **Watches Clock.** Sends Chasers on Day 1, 7, 14. |
| **Paid** | **STOPS.** Cancels all future chasers instantly. |
| **Disputed** | **ALERTS.** Stops chasers. Notifies AOGRL Owner to intervene. |

### Example Scenarios
1.  **"I want to send an invoice."** -> Add row, set Approval to `Approved`. Done.
2.  **"Client just paid."** -> Find row, set Payment to `Paid`. Done.
3.  **"Client is angry."** -> Find row, set Payment to `Disputed`. Done.

**You are in control.**
