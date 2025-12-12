import requests

API_URL = "192.168.3.47:10003"

def get_by_pkg_name(pkg_name: str):
    url = f"http://{API_URL}/api/apps/pkg_name/{pkg_name}"
    try:
        response = requests.get(url)
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error: {e}")
        return None

def main():
    # com.appbyme.app138834.hm
    for x in range(7372, 43537):
        pkg_name = f"com.appbyme.app{x}.hm"
        print(f"\rguessing {pkg_name}", end="", flush=True)
        result = get_by_pkg_name(pkg_name)
        if result is not None and result['success']:
            print(f"Found: {result}")
        else:
            print("\rNot found", flush=True, end="")

if __name__ == "__main__":
    main()
