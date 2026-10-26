# Wallet App

A personal finance tracking application built with Flutter. The app helps users manage their income, expenses, and transfers between different financial sources. It also supports SMS parsing to identify transaction details from bank messages and simplify transaction entry.

The application uses Hive for local data storage and provides customizable categories, sources, and SMS mapping rules to make transaction management more flexible.

## Features

### Transaction Management

- Add income and expense transactions.
- Record transfers between different sources.
- Add notes to transactions for additional details.
- Edit and manage transaction records.
- View transaction history.
- Assign categories and sources to transactions.

### Source Management

- Add custom sources such as bank accounts, cash, and digital wallets.
- Maintain separate transaction records for each source.
- Track balances for individual sources.
- Transfer amounts from one source to another.
- View transactions associated with a particular source.

### Category Management

- Create custom categories for income and expenses.
- Organize transactions using categories.
- Assign categories to transactions identified through SMS parsing.
- Customize categories according to individual tracking requirements.

### Balance Visibility

- Show or hide wallet balances from the main interface.
- Keep financial amounts hidden when displaying the application around others.
- Toggle balance visibility whenever required.

### SMS Parsing and Transaction Detection

SMS parsing is one of the main features of the application. The app can process supported financial SMS messages to identify transaction details and reduce manual data entry.

- Read relevant SMS messages when the user opens the application.
- Parse transaction details from supported bank messages.
- Identify information such as transaction amount, transaction type, and source.
- Use configurable templates to extract transaction details from different SMS formats.
- Avoid adding duplicate transactions through transaction identification and duplicate checks.
- Review detected transactions before adding them to the transaction history.

### Custom SMS Mapping

The application allows users to configure how parsed SMS transactions are categorized.

- Map bank or account identifiers to custom sources.
- Map transaction descriptions to custom categories.
- Configure mapping rules for different SMS formats.
- Assign priorities to mapping rules.
- Use priority to determine which matching rule should take precedence when multiple rules match.
- Update mappings without changing the application code.

This allows users to customize transaction classification based on their own accounts, spending habits, and SMS formats.

## Tech Stack

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform mobile application |
| Dart | Application programming language |
| Hive | Local database |
| Flutter Bloc / Cubit | State management |
| Android SMS APIs and permissions | Accessing supported SMS messages |
| Git | Version control |

*The SMS functionality depends on the permissions and platform capabilities available to the application.*

## How SMS Parsing Works

The SMS transaction workflow is designed to reduce the effort required to record financial transactions manually.

1. The user opens the application.
2. The application checks for permission to access SMS messages.
3. Relevant messages are retrieved and checked against the last synchronization point.
4. Supported message formats are processed using configured SMS templates.
5. Transaction details are extracted from matching messages.
6. Mapping rules determine the appropriate source and category, considering their configured priorities.
7. Duplicate checks are performed to avoid processing the same transaction more than once.
8. Detected transactions are presented for review.
9. The user can add an eligible transaction with a single action.

This approach keeps the user in control of which detected transactions are added to the wallet.

## Transaction Types

The application supports three main transaction types.

| Type | Description | Example |
|---|---|---|
| Income | Records money received into a source. | Salary credited to a bank account |
| Expense | Records money spent from a source. | Payment made using a debit card |
| Transfer | Records money moved between two sources. | Transfer from a bank account to a digital wallet |

### Transfers Between Sources

Transfers allow users to move money between their own financial sources without incorrectly recording the movement as income or an expense.

For example, transferring ₹2,000 from a bank account to a cash source should reduce the bank balance and increase the cash balance.

The transaction records should retain the source and destination so the movement can be tracked accurately.

## Local Data Storage

The application uses Hive as its local database.

Hive stores application data on the device, allowing users to access their transaction history and configuration without requiring a remote database for the core functionality.

The application can maintain local records for:

- Transactions
- Categories
- Sources
- SMS templates
- SMS field configurations
- Source and category mapping rules
- Mapping priorities
- SMS synchronization information

The exact data models and stored fields depend on the implementation.

## Getting Started

### Prerequisites

Install the following tools before setting up the project:

- Flutter SDK
- Dart SDK compatible with the Flutter version
- Android Studio or Visual Studio Code
- Android SDK for Android development
- Git

### 1. Clone the Repository

```bash
git clone <repository-url>
cd <repository-directory>
```

### 2. Install Dependencies

Run the following command from the project directory:

```bash
flutter pub get
```

### 3. Generate Hive Adapters

If the project uses Hive model code generation, generate the required adapters:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Run this command only if the project uses `build_runner` and generated Hive adapters.

### 4. Run the Application

Connect an Android device or start an emulator, then execute:

```bash
flutter run
```

### 5. Configure SMS Permissions

On Android, SMS access requires the appropriate permissions and runtime permission handling.

Grant the required permissions when prompted if SMS parsing is enabled.

SMS access is subject to Android platform restrictions and applicable app distribution policies. The application should request only the permissions necessary for its intended functionality.

## Project Structure

An example Flutter project structure is shown below. Adjust it to match the actual repository.

```text
wallet-app/
├── android/
├── ios/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   ├── theme/
│   │   └── utils/
│   ├── data/
│   │   ├── models/
│   │   ├── repositories/
│   │   └── services/
│   ├── features/
│   │   ├── home/
│   │   ├── transactions/
│   │   ├── sources/
│   │   ├── categories/
│   │   ├── sms_parsing/
│   │   └── settings/
│   ├── widgets/
│   └── main.dart
├── test/
├── pubspec.yaml
└── README.md
```

## Privacy

The application is designed around local financial data storage.

- Transaction records are stored locally using Hive.
- SMS access should be limited to the functionality required for transaction detection.
- Users should be able to review detected transactions before adding them.
- Sensitive financial information should not be included in logs or exposed unnecessarily.
- Appropriate safeguards should be used when displaying account balances.

SMS messages and financial records are sensitive information. Their handling should follow applicable platform requirements and the permissions granted by the user.

## Future Improvements

- Monthly income and expense summaries.
- Spending analytics by category.
- Budget creation and tracking.
- Transaction search and advanced filtering.
- Export transaction history to CSV or Excel.
- Backup and restore functionality.
- Improved support for different bank SMS formats.
- Additional transaction insights and reports.

## Author

Austin J

Associate Software Engineer

GitHub: https://github.com/AustinJNilavoor
