const API_BASE_URL = "https://zest-dev.sitespectrum.dev/api/Admin";

export interface User {
  id: number;
  userName: string;
  email: string;
  height: number;
  weight: number;
  gender: string;
  goal: string;
  activity: string;
  birth: string;
  profilePicture?: string;
}

const getAuthHeaders = () => {
  const token = localStorage.getItem("admin_token");
  return {
    "Content-Type": "application/json",
    "Authorization": token ? `Bearer ${token}` : "",
  };
};

export const loginAdmin = async (username: string, password: string) => {
  const response = await fetch(`${API_BASE_URL}/login`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      username: username,
      password: password,
    }),
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    throw new Error(errorData.message || "Hibás felhasználónév vagy jelszó!");
  }

  return response.json(); 
};

export const getUsers = async (): Promise<User[]> => {
  const response = await fetch(`${API_BASE_URL}/users`, {
    headers: getAuthHeaders(),
  });

  if (response.status === 401) {
    throw new Error("unauthorized");
  }
  
  if (!response.ok) {
    throw new Error("Hiba a felhasználók lekérésekor");
  }
  
  return response.json();
};

export const deleteUser = async (id: number): Promise<void> => {
  const response = await fetch(`${API_BASE_URL}/users/${id}`, {
    method: "DELETE",
    headers: getAuthHeaders(),
  });
  
  if (response.status === 401) {
    throw new Error("unauthorized");
  }

  if (!response.ok) {
    throw new Error("Hiba történt a törlés során");
  }
};

export const updateUser = async (id: number, data: Partial<User>): Promise<void> => {
  const response = await fetch(`${API_BASE_URL}/users/${id}`, {
    method: "PUT",
    headers: getAuthHeaders(),
    body: JSON.stringify(data),
  });

  if (response.status === 401) throw new Error("unauthorized");
  if (!response.ok) throw new Error("Hiba történt a frissítés során");
};

export const removeUserProfilePicture = async (id: number): Promise<void> => {
  const response = await fetch(`${API_BASE_URL}/users/${id}/profile-picture`, {
    method: "DELETE",
    headers: getAuthHeaders(),
  });

  if (response.status === 401) throw new Error("unauthorized");
  if (!response.ok) throw new Error("Hiba történt a profilkép törlése során");
};