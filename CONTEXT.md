# PROJECT CONTEXT: Transaction note

## 1. Core Architecture & Tech Stack

- **Language/Framework:** Flutter
- **Database/Storage:** Firebase firestore
- **Caching Strategy:** Once it fetched from firestore, please keep on on the cache at least 15 minutes, or until that data invalid because new data added on that list. avoid do multiple fetch data if the data not always changed, need to defince strategy the best way to do refetch with consider the firestore read efficiency
- **Build Target:** android

## 2. Code Style & Design Patterns

- **Error Handling:** Show the error message message on snackbar with correct icon
- please help to revmoew unused import on the changed file
- on the new created file, especially for the screen and components, please ensure one widget per file
- if possible avoid using deprecated method or parameter

## 3. UI/UX design

- **theme:** follow the current implementation with dark and light mode, set light as default
- please use indonesian rupiah as currency, also for displaying the amount use the suiateble format for rupiah
