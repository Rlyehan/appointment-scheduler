#! /bin/bash

# start timer
START_TIME=$(date +%s)

# define PSQL connection
PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

# define script header
echo -e "\n~~~~~ My Salon ~~~~~\n"
echo -e "Welcome to My Salon, how can I help you?\n"

# Loop to get valid Service ID from user
while true; do
# Get the list of services from the services table
SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id")

# Loop through the list of services and display them with a number prefix
echo "$SERVICES" | sed 's/|/ /g' | while read SERVICE_ID  SERVICE_NAME
  do
    printf "%s) %s\n" "$SERVICE_ID" "$SERVICE_NAME"
  done

# Prompt user to enter a service_id
echo "Please enter a service_id:"
read SERVICE_ID_SELECTED

    # Validate service_id input
    if ! [[ $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]; then
        echo "Invalid input. Please enter a numeric service_id."
    else
        service_exists=$($PSQL "SELECT COUNT(*) FROM services WHERE service_id=$SERVICE_ID_SELECTED")
        if [[ $service_exists -eq 0 ]]; then
            echo "I could not find that service. What would you like today?"
        else
          SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id=$SERVICE_ID_SELECTED")
          break
        fi
    fi
done

# Prompt user to enter a phone number
while true; do
  echo "Please enter your phone number:"
  read CUSTOMER_PHONE
  if ! [[ $CUSTOMER_PHONE =~ ^[0-9]{3}-[0-9]{3}-[0-9]{4}$ ]]; then
      echo "Invalid phone number. Please enter a phone number in the format 555-555-5555."
  else
    break
  fi
done

# Check if the phone number exists
CUSTOMER_NAME=$($PSQL"SELECT name FROM customers WHERE phone='$CUSTOMER_PHONE'")
if [[ -z $CUSTOMER_NAME ]]; then
    # Prompt user to enter a name
    echo "I don't have a record for that phone number, what's your name?"
    read CUSTOMER_NAME

    # Insert the customer's name and phone number into the customers table
    ADD_CLIENT=$($PSQL "INSERT INTO customers (name, phone) VALUES ('$CUSTOMER_NAME', '$CUSTOMER_PHONE')")
fi

while true; do
  echo -e "\n$(echo "What time would you like your $SERVICE_NAME, $CUSTOMER_NAME" | sed -r 's/ +/ /g')?"
  read SERVICE_TIME
  if ! [[ $SERVICE_TIME =~ ^(0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]$ || $SERVICE_TIME =~ ^([01][0-9]|2[0-3]):[0-5][0-9](am|AM|pm|PM)$ ]]; then
    echo "Invalid time format. Please enter a valid time format (HH:MM or H:MM am/pm)."
  else
    break
  fi
done

CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")
INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES ('$CUSTOMER_ID', $SERVICE_ID_SELECTED, '$SERVICE_TIME')")
if [[ $INSERT_APPOINTMENT_RESULT != "INSERT 0 1" ]]
then
  echo "sorry, something went wrong"
else
 printf "I have put you down for a %s at %s, %s\n" "$SERVICE_NAME" "$SERVICE_TIME" "$CUSTOMER_NAME"
fi

# end timer
END_TIME=$(date +%s)

# calcculate the total run time
ELAPSED_TIME=$((END_TIME - START_TIME))
printf "Elapsed time: %02d:%02d:%02d\n" "$((ELAPSED_TIME/3600))" "$((ELAPSED_TIME%3600/60))" "$((ELAPSED_TIME%60))"
