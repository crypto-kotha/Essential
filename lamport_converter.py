def lamports_to_usdc(lamports, sol_value_usd):
    sol = lamports / 1_000_000_000
    usdc = sol * sol_value_usd
    return usdc

def main():
    sol_value_usd = float(input("Enter the current SOL value in USD: "))
    lamports = int(input("Enter the amount in Lamports: "))
    usdc_value = lamports_to_usdc(lamports, sol_value_usd)
    print(f"{lamports} Lamports is equivalent to {usdc_value:.6f} USDC based on the current SOL value of {sol_value_usd} USD.")

if __name__ == "__main__":
    main()
