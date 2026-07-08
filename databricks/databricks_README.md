# Catalog structure
<pre>
chess_games catalog  
├── bronze/  
│       └── volume/  
│               └── json/  
│                   ├── yyyy_mm.json  
│                   ├── yyyy_mm.json  
│                   └── yyyy_mm.json  
│     
├── silver/  
│       └── tables/  
│               └── games  
│  
└── gold  
        └── tables/     
                ├── accuracy  
                ├── opening_groups  
                ├── opponent_elo  
                ├── result  
                └── timed_resuld  
</pre>


# Jobs config
### tasks :
to_silver (bronze_to_silver.ipynb)   
\>> to_gold (silver_to_gold.ipynb)()

### parameters :
- MAIL : 'Chess.com_account_email'
- USERNAME : 'Chess.com_account_username'

### Schedules & Triggers :
File arrival on /Volumes/chess_games/bronze/json/
