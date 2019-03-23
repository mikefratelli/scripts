#!/usr/bin/python3.6

#Generate a dice roll!

import random
num = input("How many die would you like to roll?" )
sides = input("How many sides on the dice?" )
def diceroll(num, sides):
    rolls = []
    for x in range(int(num)):
        rolls.append(random.randint(1,int(sides)))
    print(f"{' '.join(str(x) for x in rolls)}")
    print(f"total is {sum(rolls)}")

diceroll(num, sides)
