import streamlit as st
import requests
import pandas as pd
import plotly.express as px
from datetime import datetime, timedelta
from streamlit_option_menu import option_menu
import json

# Page configuration
st.set_page_config(
    page_title="Complete Fertility Services Admin Dashboard",
    page_icon="🏥",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Configuration
API_BASE_URL = "http://backend:8000/api/v1"
ADMIN_TOKEN = st.session_state.get('admin_token', '')

# Custom CSS
st.markdown("""
<style>
    .main-header {
        font-size: 2.5rem;
        font-weight: bold;
        color: #1f77b4;
        text-align: center;
        margin-bottom: 2rem;
    }
    .status-active { color: #28a745; font-weight: bold; }
    .status-inactive { color: #dc3545; font-weight: bold; }
    .status-pending { color: #ffc107; font-weight: bold; }
    .status-verified { color: #28a745; font-weight: bold; }
    .status-unverified { color: #dc3545; font-weight: bold; }
    .medical-record-card {
        border: 1px solid #ddd;
        border-radius: 8px;
        padding: 1rem;
        margin: 0.5rem 0;
        background-color: #f9f9f9;
    }
    .doctor-card {
        border: 1px solid #e0e0e0;
        border-radius: 8px;
        padding: 1rem;
        margin: 0.5rem 0;
        background-color: #fafafa;
    }
</style>
""", unsafe_allow_html=True)

def get_headers():
    """Get authorization headers"""
    return {"Authorization": f"Bearer {ADMIN_TOKEN}"} if ADMIN_TOKEN else {}

def authenticate_admin(email, password):
    """Authenticate admin user"""
    try:
        response = requests.post(
            f"{API_BASE_URL}/auth/login",
            json={"email": email, "password": password}
        )
        if response.status_code == 200:
            data = response.json()
            return data.get('access_token')
        return None
    except Exception as e:
        st.error(f"Authentication error: {str(e)}")
        return None

# API Functions (simplified for brevity)
def get_users(skip=0, limit=100):
    try:
        response = requests.get(f"{API_BASE_URL}/users/?skip={skip}&limit={limit}", headers=get_headers())
        return response.json() if response.status_code == 200 else []
    except Exception as e:
        st.error(f"Error fetching users: {str(e)}")
        return []

def get_dashboard_data():
    try:
        response = requests.get(f"{API_BASE_URL}/admin/dashboard", headers=get_headers())
        return response.json() if response.status_code == 200 else None
    except Exception as e:
        st.error(f"Error fetching dashboard data: {str(e)}")
        return None

def verify_user(user_id, verification_status):
    try:
        response = requests.post(
            f"{API_BASE_URL}/admin/users/{user_id}/verify",
            json={"is_verified": verification_status},
            headers=get_headers()
        )
        return response.status_code == 200
    except Exception as e:
        st.error(f"Error verifying user: {str(e)}")
        return False

def delete_user(user_id):
    try:
        response = requests.delete(f"{API_BASE_URL}/admin/users/{user_id}", headers=get_headers())
        return response.status_code == 200
    except Exception as e:
        st.error(f"Error deleting user: {str(e)}")
        return False

def get_user_medical_records(user_id):
    try:
        response = requests.get(f"{API_BASE_URL}/admin/users/{user_id}/medical-records", headers=get_headers())
        return response.json() if response.status_code == 200 else []
    except Exception as e:
        st.error(f"Error fetching medical records: {str(e)}")
        return []

def verify_medical_record(record_id, verification_status, notes=""):
    try:
        response = requests.post(
            f"{API_BASE_URL}/admin/medical-records/{record_id}/verify",
            json={"is_verified": verification_status, "verification_notes": notes},
            headers=get_headers()
        )
        return response.status_code == 200
    except Exception as e:
        st.error(f"Error verifying medical record: {str(e)}")
        return False

def get_hospitals():
    try:
        response = requests.get(f"{API_BASE_URL}/admin/hospitals/", headers=get_headers())
        return response.json() if response.status_code == 200 else []
    except Exception as e:
        st.error(f"Error fetching hospitals: {str(e)}")
        return []

def create_hospital(hospital_data):
    try:
        response = requests.post(f"{API_BASE_URL}/admin/hospitals/", json=hospital_data, headers=get_headers())
        return response.status_code == 201
    except Exception as e:
        st.error(f"Error creating hospital: {str(e)}")
        return False

def add_doctor_to_hospital(hospital_id, doctor_data):
    try:
        response = requests.post(f"{API_BASE_URL}/admin/hospitals/{hospital_id}/doctors", json=doctor_data, headers=get_headers())
        return response.status_code == 201
    except Exception as e:
        st.error(f"Error adding doctor: {str(e)}")
        return False

# Dashboard Pages
def show_login():
    st.markdown('<h1 class="main-header">🏥 Complete Admin Dashboard</h1>', unsafe_allow_html=True)
    
    with st.form("login_form"):
        email = st.text_input("Email", placeholder="admin@fertilityservices.com")
        password = st.text_input("Password", type="password")
        submit = st.form_submit_button("Login", use_container_width=True)
        
        if submit:
            if email and password:
                token = authenticate_admin(email, password)
                if token:
                    st.session_state['admin_token'] = token
                    st.session_state['admin_email'] = email
                    st.success("Login successful!")
                    st.rerun()
                else:
                    st.error("Invalid credentials")
            else:
                st.error("Please enter both email and password")

def show_dashboard():
    st.markdown('<h1 class="main-header">📊 Dashboard Overview</h1>', unsafe_allow_html=True)
    
    dashboard_data = get_dashboard_data()
    if not dashboard_data:
        st.error("Failed to load dashboard data")
        return
    
    # Key metrics
    col1, col2, col3, col4 = st.columns(4)
    with col1:
        st.metric("Total Users", dashboard_data['users']['total'], delta=dashboard_data['users']['new_last_30_days'])
    with col2:
        st.metric("Total Hospitals", dashboard_data['hospitals']['total'], delta=dashboard_data['hospitals']['verified'])
    with col3:
        st.metric("Total Appointments", dashboard_data['appointments']['total'], delta=dashboard_data['appointments']['new_last_30_days'])
    with col4:
        st.metric("Total Revenue", f"${dashboard_data['payments']['total_revenue']:,.2f}", delta=f"{dashboard_data['payments']['success_rate']:.1f}%")

def show_users_management():
    st.markdown('<h1 class="main-header">👥 Enhanced User Management</h1>', unsafe_allow_html=True)
    
    users = get_users()
    if not users:
        st.info("No users found")
        return
    
    df = pd.DataFrame(users)
    
    # Filters
    col1, col2, col3, col4 = st.columns(4)
    with col1:
        user_type_filter = st.selectbox("Filter by Type", ["All"] + list(df['user_type'].unique()))
    with col2:
        status_filter = st.selectbox("Filter by Status", ["All", "Active", "Inactive"])
    with col3:
        verified_filter = st.selectbox("Filter by Verification", ["All", "Verified", "Unverified"])
    with col4:
        search_term = st.text_input("Search by name/email")
    
    # Apply filters
    filtered_df = df.copy()
    if user_type_filter != "All":
        filtered_df = filtered_df[filtered_df['user_type'] == user_type_filter]
    if status_filter != "All":
        filtered_df = filtered_df[filtered_df['is_active'] == (status_filter == "Active")]
    if verified_filter != "All":
        filtered_df = filtered_df[filtered_df['is_verified'] == (verified_filter == "Verified")]
    if search_term:
        filtered_df = filtered_df[
            filtered_df['first_name'].str.contains(search_term, case=False, na=False) |
            filtered_df['last_name'].str.contains(search_term, case=False, na=False) |
            filtered_df['email'].str.contains(search_term, case=False, na=False)
        ]
    
    st.subheader(f"Users ({len(filtered_df)})")
    
    for _, user in filtered_df.iterrows():
        with st.expander(f"{user['first_name']} {user['last_name']} - {user['email']} ({user['user_type']})"):
            col1, col2, col3 = st.columns(3)
            
            with col1:
                st.write(f"**Type:** {user['user_type']}")
                st.write(f"**Phone:** {user.get('phone', 'N/A')}")
                st.write(f"**Created:** {user['created_at'][:10]}")
            
            with col2:
                status_class = "status-active" if user['is_active'] else "status-inactive"
                st.markdown(f"**Status:** <span class='{status_class}'>{'Active' if user['is_active'] else 'Inactive'}</span>", unsafe_allow_html=True)
                
                verified_class = "status-verified" if user['is_verified'] else "status-unverified"
                st.markdown(f"**Verified:** <span class='{verified_class}'>{'Yes' if user['is_verified'] else 'No'}</span>", unsafe_allow_html=True)
            
            with col3:
                col3a, col3b = st.columns(2)
                
                with col3a:
                    verify_text = "Unverify" if user['is_verified'] else "Verify"
                    if st.button(verify_text, key=f"verify_user_{user['id']}"):
                        new_status = not user['is_verified']
                        if verify_user(user['id'], new_status):
                            st.success(f"User {'verified' if new_status else 'unverified'}!")
                            st.rerun()
                
                with col3b:
                    if st.button("🗑️ Delete", key=f"delete_user_{user['id']}"):
                        if st.session_state.get(f"confirm_delete_{user['id']}", False):
                            if delete_user(user['id']):
                                st.success("User deleted!")
                                st.rerun()
                        else:
                            st.session_state[f"confirm_delete_{user['id']}"] = True
                            st.warning("Click again to confirm deletion")

def show_medical_records_verification():
    st.markdown('<h1 class="main-header">📋 Medical Records Verification</h1>', unsafe_allow_html=True)
    
    users = get_users()
    donor_surrogate_users = [user for user in users if user['user_type'] in ['sperm_donor', 'egg_donor', 'surrogate']]
    
    if not donor_surrogate_users:
        st.info("No donors or surrogates found")
        return
    
    st.subheader(f"Medical Records ({len(donor_surrogate_users)} users)")
    
    for user in donor_surrogate_users:
        with st.expander(f"📋 {user['first_name']} {user['last_name']} - {user['user_type'].replace('_', ' ').title()}"):
            medical_records = get_user_medical_records(user['id'])
            
            if not medical_records:
                st.info("No medical records submitted yet")
                continue
            
            st.write(f"**User:** {user['first_name']} {user['last_name']} ({user['email']})")
            st.write(f"**Type:** {user['user_type'].replace('_', ' ').title()}")
            st.write(f"**Total Records:** {len(medical_records)}")
            
            for record in medical_records:
                with st.container():
                    st.markdown('<div class="medical-record-card">', unsafe_allow_html=True)
                    
                    col1, col2, col3 = st.columns([2, 1, 1])
                    
                    with col1:
                        st.write(f"**File:** {record.get('file_name', 'Unknown')}")
                        st.write(f"**Type:** {record.get('record_type', 'other').replace('_', ' ').title()}")
                        st.write(f"**Uploaded:** {record.get('created_at', '')[:10]}")
                    
                    with col2:
                        verification_status = record.get('is_verified', False)
                        status_class = "status-verified" if verification_status else "status-unverified"
                        status_text = "Verified" if verification_status else "Unverified"
                        st.markdown(f"**Status:** <span class='{status_class}'>{status_text}</span>", unsafe_allow_html=True)
                    
                    with col3:
                        if not verification_status:
                            if st.button("✅ Verify", key=f"verify_record_{record['id']}"):
                                if verify_medical_record(record['id'], True, "Verified by admin"):
                                    st.success("Record verified!")
                                    st.rerun()
                        
                        if st.button("❌ Reject", key=f"reject_record_{record['id']}"):
                            if verify_medical_record(record['id'], False, "Rejected by admin"):
                                st.success("Record rejected!")
                                st.rerun()
                    
                    st.markdown('</div>', unsafe_allow_html=True)

def show_hospitals_management():
    st.markdown('<h1 class="main-header">🏥 Enhanced Hospital Management</h1>', unsafe_allow_html=True)
    
    tab1, tab2 = st.tabs(["🏥 All Hospitals", "➕ Add Hospital"])
    
    with tab1:
        hospitals = get_hospitals()
        if not hospitals:
            st.info("No hospitals found")
        else:
            st.subheader(f"Hospitals ({len(hospitals)})")
            
            for hospital in hospitals:
                with st.expander(f"{hospital['name']} - {hospital['city']}, {hospital['state']}"):
                    col1, col2 = st.columns(2)
                    
                    with col1:
                        st.write(f"**License:** {hospital['license_number']}")
                        st.write(f"**Email:** {hospital.get('email', 'N/A')}")
                        st.write(f"**Phone:** {hospital.get('phone', 'N/A')}")
                        st.write(f"**Rating:** {hospital['rating']}/5.0")
                    
                    with col2:
                        st.write(f"**Address:** {hospital['address']}")
                        st.write(f"**City:** {hospital['city']}")
                        st.write(f"**State:** {hospital['state']}")
                        st.write(f"**Country:** {hospital['country']}")
                        
                        verified_class = "status-verified" if hospital['is_verified'] else "status-pending"
                        st.markdown(f"**Status:** <span class='{verified_class}'>{'Verified' if hospital['is_verified'] else 'Pending'}</span>", unsafe_allow_html=True)
    
    with tab2:
        st.subheader("Add New Hospital")
        
        with st.form("add_hospital_form"):
            col1, col2 = st.columns(2)
            
            with col1:
                name = st.text_input("Hospital Name*")
                license_number = st.text_input("License Number*")
                email = st.text_input("Email*")
                phone = st.text_input("Phone*")
            
            with col2:
                address = st.text_area("Address*")
                city = st.text_input("City*")
                state = st.text_input("State*")
                country = st.text_input("Country*")
            
            description = st.text_area("Description")
            is_verified = st.checkbox("Verified")
            rating = st.slider("Rating", 0.0, 5.0, 4.0, 0.1)
            
            submit = st.form_submit_button("Add Hospital", use_container_width=True)
            
            if submit:
                if name and license_number and email and phone and address and city and state and country:
                    hospital_data = {
                        "name": name,
                        "license_number": license_number,
                        "email": email,
                        "phone": phone,
                        "address": address,
                        "city": city,
                        "state": state,
                        "country": country,
                        "description": description,
                        "is_verified": is_verified,
                        "rating": rating
                    }
                    
                    if create_hospital(hospital_data):
                        st.success("Hospital added successfully!")
                        st.rerun()
                    else:
                        st.error("Failed to add hospital")
                else:
                    st.error("Please fill in all required fields marked with *")

def show_doctor_management():
    st.markdown('<h1 class="main-header">👨‍⚕️ Doctor Management</h1>', unsafe_allow_html=True)
    
    hospitals = get_hospitals()
    if not hospitals:
        st.info("No hospitals found. Please add hospitals first.")
        return
    
    hospital_options = {f"{hospital['name']} - {hospital['city']}": hospital['id'] for hospital in hospitals}
    selected_hospital_name = st.selectbox("Select Hospital", list(hospital_options.keys()))
    
    if selected_hospital_name:
        hospital_id = hospital_options[selected_hospital_name]
        
        st.subheader("Add Doctor to Hospital")
        
        with st.form("add_doctor_form"):
            col1, col2 = st.columns(2)
            
            with col1:
                first_name = st.text_input("First Name*")
                last_name = st.text_input("Last Name*")
                email = st.text_input("Email*")
                phone = st.text_input("Phone*")
            
            with col2:
                specialization = st.text_input("Specialization*")
                license_number = st.text_input("License Number*")
                years_experience = st.number_input("Years of Experience", min_value=0, max_value=50, value=5)
                rating = st.slider("Rating", 0.0, 5.0, 4.0, 0.1)
            
            bio = st.text_area("Bio")
            
            submit = st.form_submit_button("Add Doctor", use_container_width=True)
            
            if submit:
                if first_name and last_name and email and phone and specialization and license_number:
                    doctor_data = {
                        "first_name": first_name,
                        "last_name": last_name,
                        "email": email,
                        "phone": phone,
                        "specialization": specialization,
                        "license_number": license_number,
                        "years_experience": years_experience,
                        "rating": rating,
                        "bio": bio
                    }
                    
                    if add_doctor_to_hospital(hospital_id, doctor_data):
                        st.success("Doctor added successfully!")
                        st.rerun()
                    else:
                        st.error("Failed to add doctor")
                else:
                    st.error("Please fill in all required fields marked with *")

# Main app
def main():
    # Check authentication
    if 'admin_token' not in st.session_state or not st.session_state['admin_token']:
        show_login()
        return
    
    # Sidebar navigation
    with st.sidebar:
        st.title("🏥 Admin Panel")
        st.write(f"Welcome, {st.session_state.get('admin_email', 'Admin')}")
        
        selected = option_menu(
            menu_title=None,
            options=["Dashboard", "Users", "Medical Records", "Hospitals", "Doctors", "Logout"],
            icons=["speedometer2", "people", "clipboard-check", "hospital", "person-badge", "box-arrow-right"],
            menu_icon="cast",
            default_index=0,
        )
        
        if selected == "Logout":
            st.session_state.clear()
            st.rerun()
    
    # Show selected page
    if selected == "Dashboard":
        show_dashboard()
    elif selected == "Users":
        show_users_management()
    elif selected == "Medical Records":
        show_medical_records_verification()
    elif selected == "Hospitals":
        show_hospitals_management()
    elif selected == "Doctors":
        show_doctor_management()

if __name__ == "__main__":
    main()
