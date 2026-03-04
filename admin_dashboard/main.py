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
    .file-preview {
        border: 1px solid #e0e0e0;
        border-radius: 4px;
        padding: 0.5rem;
        background-color: #fafafa;
        margin: 0.5rem 0;
    }
    .file-link {
        color: #1f77b4;
        text-decoration: none;
        font-weight: bold;
    }
    .file-link:hover {
        text-decoration: underline;
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

def get_all_medical_records():
    try:
        response = requests.get(f"{API_BASE_URL}/medical-records/admin/all", headers=get_headers())
        return response.json() if response.status_code == 200 else []
    except Exception as e:
        st.error(f"Error fetching medical records: {str(e)}")
        return []

def get_medical_record_file_url(record_id):
    """Get the URL for viewing a medical record file"""
    return f"{API_BASE_URL}/medical-records/{record_id}/file"

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


def delete_medical_record(record_id):
    try:
        response = requests.delete(f"{API_BASE_URL}/medical-records/admin/{record_id}", headers=get_headers())
        return response.status_code == 200
    except Exception as e:
        st.error(f"Error deleting medical record: {str(e)}")
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
        if response.status_code == 200:
            return True
        else:
            st.error(f"Failed to create hospital. Status: {response.status_code}, Response: {response.text}")
            return False
    except Exception as e:
        st.error(f"Error creating hospital: {str(e)}")
        return False

def get_all_doctors():
    try:
        response = requests.get(f"{API_BASE_URL}/admin/doctors/", headers=get_headers())
        return response.json() if response.status_code == 200 else []
    except Exception as e:
        st.error(f"Error fetching doctors: {str(e)}")
        return []

def get_all_appointments():
    try:
        response = requests.get(f"{API_BASE_URL}/admin/appointments/all", headers=get_headers())
        return response.json() if response.status_code == 200 else []
    except Exception as e:
        st.error(f"Error fetching appointments: {str(e)}")
        return []

def get_appointment_details(appointment_id):
    try:
        response = requests.get(f"{API_BASE_URL}/appointments/{appointment_id}", headers=get_headers())
        return response.json() if response.status_code == 200 else None
    except Exception as e:
        st.error(f"Error fetching appointment details: {str(e)}")
        return None

def update_appointment_status(appointment_id, status):
    try:
        response = requests.put(
            f"{API_BASE_URL}/appointments/{appointment_id}",
            json={"status": status},
            headers=get_headers()
        )
        return response.status_code == 200
    except Exception as e:
        st.error(f"Error updating appointment status: {str(e)}")
        return False

def delete_appointment(appointment_id):
    try:
        response = requests.delete(f"{API_BASE_URL}/appointments/{appointment_id}", headers=get_headers())
        return response.status_code == 200
    except Exception as e:
        st.error(f"Error deleting appointment: {str(e)}")
        return False

def get_all_payments():
    try:
        response = requests.get(f"{API_BASE_URL}/admin/payments/all", headers=get_headers())
        return response.json() if response.status_code == 200 else []
    except Exception as e:
        st.error(f"Error fetching payments: {str(e)}")
        return []

def get_wallet_statistics():
    try:
        response = requests.get(f"{API_BASE_URL}/admin/wallet/statistics", headers=get_headers())
        return response.json() if response.status_code == 200 else None
    except Exception as e:
        st.error(f"Error fetching wallet statistics: {str(e)}")
        return None

def get_all_wallet_transactions(skip=0, limit=100, user_id=None, transaction_type=None, status=None):
    try:
        params = {"skip": skip, "limit": limit}
        if user_id:
            params["user_id"] = user_id
        if transaction_type:
            params["transaction_type"] = transaction_type
        if status:
            params["status"] = status
            
        response = requests.get(f"{API_BASE_URL}/admin/wallet/transactions", params=params, headers=get_headers())
        return response.json() if response.status_code == 200 else []
    except Exception as e:
        st.error(f"Error fetching wallet transactions: {str(e)}")
        return []

def get_users_with_wallets(skip=0, limit=100):
    try:
        response = requests.get(f"{API_BASE_URL}/admin/wallet/users", params={"skip": skip, "limit": limit}, headers=get_headers())
        return response.json() if response.status_code == 200 else []
    except Exception as e:
        st.error(f"Error fetching users with wallets: {str(e)}")
        return []

def adjust_user_wallet_balance(user_id, amount, operation, reason):
    try:
        response = requests.post(
            f"{API_BASE_URL}/admin/wallet/users/{user_id}/adjust-balance",
            json={"amount": amount, "operation": operation, "reason": reason},
            headers=get_headers()
        )
        if response.status_code == 200:
            return response.json()
        else:
            st.error(f"Failed to adjust wallet balance. Status: {response.status_code}, Response: {response.text}")
            return None
    except Exception as e:
        st.error(f"Error adjusting wallet balance: {str(e)}")
        return None

def update_payment_status(payment_id, status):
    try:
        response = requests.put(
            f"{API_BASE_URL}/admin/payments/{payment_id}/status",
            json={"status": status},
            headers=get_headers()
        )
        return response.status_code == 200
    except Exception as e:
        st.error(f"Error updating payment status: {str(e)}")
        return False

def delete_payment(payment_id):
    try:
        response = requests.delete(f"{API_BASE_URL}/admin/payments/{payment_id}", headers=get_headers())
        return response.status_code == 200
    except Exception as e:
        st.error(f"Error deleting payment: {str(e)}")
        return False

# Services Management Functions

def get_all_services():
    try:
        response = requests.get(f"{API_BASE_URL}/services/admin/all", headers=get_headers())
        return response.json() if response.status_code == 200 else []
    except Exception as e:
        st.error(f"Error fetching services: {str(e)}")
        return []

def create_service(service_data):
    try:
        response = requests.post(f"{API_BASE_URL}/services/", json=service_data, headers=get_headers())
        if response.status_code == 200:
            return True
        else:
            st.error(f"Failed to create service. Status: {response.status_code}, Response: {response.text}")
            return False
    except Exception as e:
        st.error(f"Error creating service: {str(e)}")
        return False

def update_service(service_id, service_data):
    try:
        response = requests.put(f"{API_BASE_URL}/services/{service_id}", json=service_data, headers=get_headers())
        if response.status_code == 200:
            return True
        else:
            st.error(f"Failed to update service. Status: {response.status_code}, Response: {response.text}")
            return False
    except Exception as e:
        st.error(f"Error updating service: {str(e)}")
        return False

def delete_service(service_id):
    try:
        response = requests.delete(f"{API_BASE_URL}/services/{service_id}", headers=get_headers())
        if response.status_code == 200:
            return True
        else:
            st.error(f"Failed to delete service. Status: {response.status_code}, Response: {response.text}")
            return False
    except Exception as e:
        st.error(f"Error deleting service: {str(e)}")
        return False

def get_service_stats():
    try:
        response = requests.get(f"{API_BASE_URL}/services/stats/overview", headers=get_headers())
        return response.json() if response.status_code == 200 else {}
    except Exception as e:
        st.error(f"Error fetching service stats: {str(e)}")
        return {}

# Payment Gateway Management Functions
def get_payment_gateways():
    try:
        response = requests.get(f"{API_BASE_URL}/payment-gateways/", headers=get_headers())
        return response.json() if response.status_code == 200 else []
    except Exception as e:
        st.error(f"Error fetching payment gateways: {str(e)}")
        return []

def get_payment_gateway(gateway):
    try:
        response = requests.get(f"{API_BASE_URL}/payment-gateways/{gateway}", headers=get_headers())
        return response.json() if response.status_code == 200 else None
    except Exception as e:
        st.error(f"Error fetching payment gateway: {str(e)}")
        return None

def create_payment_gateway_config(gateway_data):
    try:
        response = requests.post(f"{API_BASE_URL}/payment-gateways/", json=gateway_data, headers=get_headers())
        if response.status_code == 200:
            return True
        else:
            st.error(f"Failed to create payment gateway config. Status: {response.status_code}, Response: {response.text}")
            return False
    except Exception as e:
        st.error(f"Error creating payment gateway config: {str(e)}")
        return False

def update_payment_gateway_config(gateway, gateway_data):
    try:
        response = requests.put(f"{API_BASE_URL}/payment-gateways/{gateway}", json=gateway_data, headers=get_headers())
        if response.status_code == 200:
            return True
        else:
            st.error(f"Failed to update payment gateway config. Status: {response.status_code}, Response: {response.text}")
            return False
    except Exception as e:
        st.error(f"Error updating payment gateway config: {str(e)}")
        return False

def activate_payment_gateway(gateway):
    try:
        response = requests.post(f"{API_BASE_URL}/payment-gateways/{gateway}/activate", headers=get_headers())
        if response.status_code == 200:
            return True
        else:
            st.error(f"Failed to activate payment gateway. Status: {response.status_code}, Response: {response.text}")
            return False
    except Exception as e:
        st.error(f"Error activating payment gateway: {str(e)}")
        return False

def deactivate_payment_gateway(gateway):
    try:
        response = requests.post(f"{API_BASE_URL}/payment-gateways/{gateway}/deactivate", headers=get_headers())
        if response.status_code == 200:
            return True
        else:
            st.error(f"Failed to deactivate payment gateway. Status: {response.status_code}, Response: {response.text}")
            return False
    except Exception as e:
        st.error(f"Error deactivating payment gateway: {str(e)}")
        return False

def test_payment_gateway(gateway):
    try:
        response = requests.post(f"{API_BASE_URL}/payment-gateways/{gateway}/test", headers=get_headers())
        return response.json() if response.status_code == 200 else {"status": "failed", "message": "Test failed"}
    except Exception as e:
        st.error(f"Error testing payment gateway: {str(e)}")
        return {"status": "failed", "message": str(e)}

def get_payment_gateway_stats():
    try:
        response = requests.get(f"{API_BASE_URL}/payment-gateways/stats/overview", headers=get_headers())
        return response.json() if response.status_code == 200 else {}
    except Exception as e:
        st.error(f"Error fetching payment gateway stats: {str(e)}")
        return {}

def get_doctor_details(doctor_id):
    try:
        response = requests.get(f"{API_BASE_URL}/admin/doctors/{doctor_id}", headers=get_headers())
        return response.json() if response.status_code == 200 else None
    except Exception as e:
        st.error(f"Error fetching doctor details: {str(e)}")
        return None

def update_doctor(doctor_id, doctor_data):
    try:
        response = requests.put(f"{API_BASE_URL}/admin/doctors/{doctor_id}", json=doctor_data, headers=get_headers())
        if response.status_code == 200:
            return True
        else:
            st.error(f"Failed to update doctor. Status: {response.status_code}, Response: {response.text}")
            return False
    except Exception as e:
        st.error(f"Error updating doctor: {str(e)}")
        return False

def delete_doctor(doctor_id):
    try:
        response = requests.delete(f"{API_BASE_URL}/admin/doctors/{doctor_id}", headers=get_headers())
        if response.status_code == 200:
            return True
        else:
            st.error(f"Failed to delete doctor. Status: {response.status_code}, Response: {response.text}")
            return False
    except Exception as e:
        st.error(f"Error deleting doctor: {str(e)}")
        return False

def add_doctor_to_hospital(hospital_id, doctor_data):
    try:
        response = requests.post(f"{API_BASE_URL}/admin/hospitals/{hospital_id}/doctors", json=doctor_data, headers=get_headers())
        if response.status_code == 201:
            return True
        else:
            st.error(f"Failed to add doctor. Status: {response.status_code}, Response: {response.text}")
            return False
    except Exception as e:
        st.error(f"Error adding doctor: {str(e)}")
        return False

def show_appointments_management():
    st.markdown('<h1 class="main-header">📅 Comprehensive Appointment Management</h1>', unsafe_allow_html=True)
    
    appointments = get_all_appointments()
    if not appointments:
        st.info("No appointments found")
        return
    
    # Create DataFrame for easier filtering
    df = pd.DataFrame(appointments)
    
    # Summary metrics
    col1, col2, col3, col4 = st.columns(4)
    with col1:
        total_appointments = len(appointments)
        st.metric("Total Appointments", total_appointments)
    
    with col2:
        pending_count = len([apt for apt in appointments if apt.get('status') == 'pending'])
        st.metric("Pending", pending_count, delta=f"{pending_count/total_appointments*100:.1f}%" if total_appointments > 0 else "0%")
    
    with col3:
        confirmed_count = len([apt for apt in appointments if apt.get('status') == 'confirmed'])
        st.metric("Confirmed", confirmed_count, delta=f"{confirmed_count/total_appointments*100:.1f}%" if total_appointments > 0 else "0%")
    
    with col4:
        completed_count = len([apt for apt in appointments if apt.get('status') == 'completed'])
        st.metric("Completed", completed_count, delta=f"{completed_count/total_appointments*100:.1f}%" if total_appointments > 0 else "0%")
    
    # Filters
    st.subheader("🔍 Filter Appointments")
    col1, col2, col3, col4 = st.columns(4)
    
    with col1:
        status_filter = st.selectbox("Filter by Status", ["All", "pending", "confirmed", "completed", "cancelled"])
    
    with col2:
        # Get unique user types from appointments (we'll need to fetch user details)
        user_type_filter = st.selectbox("Filter by User Type", ["All", "patient", "sperm_donor", "egg_donor", "surrogate", "hospital"])
    
    with col3:
        date_filter = st.selectbox("Filter by Date", ["All", "Today", "This Week", "This Month", "Last 30 Days"])
    
    with col4:
        search_term = st.text_input("🔍 Search by patient name or ID")
    
    # Apply filters
    filtered_appointments = appointments.copy()
    
    if status_filter != "All":
        filtered_appointments = [apt for apt in filtered_appointments if apt.get('status') == status_filter]
    
    # Date filtering
    if date_filter != "All":
        from datetime import datetime, timedelta
        now = datetime.now()
        
        if date_filter == "Today":
            today = now.date()
            filtered_appointments = [
                apt for apt in filtered_appointments 
                if apt.get('appointment_date') and apt['appointment_date'][:10] == str(today)
            ]
        elif date_filter == "This Week":
            week_start = (now - timedelta(days=now.weekday())).date()
            filtered_appointments = [
                apt for apt in filtered_appointments 
                if apt.get('appointment_date') and apt['appointment_date'][:10] >= str(week_start)
            ]
        elif date_filter == "This Month":
            month_start = now.replace(day=1).date()
            filtered_appointments = [
                apt for apt in filtered_appointments 
                if apt.get('appointment_date') and apt['appointment_date'][:10] >= str(month_start)
            ]
        elif date_filter == "Last 30 Days":
            thirty_days_ago = (now - timedelta(days=30)).date()
            filtered_appointments = [
                apt for apt in filtered_appointments 
                if apt.get('appointment_date') and apt['appointment_date'][:10] >= str(thirty_days_ago)
            ]
    
    # Search filtering
    if search_term:
        # This is a simplified search - in a real implementation, you'd join with user data
        filtered_appointments = [
            apt for apt in filtered_appointments 
            if search_term.lower() in str(apt.get('user_id', '')).lower() or 
               search_term.lower() in str(apt.get('id', '')).lower()
        ]
    
    st.subheader(f"📋 Appointments ({len(filtered_appointments)})")
    
    if not filtered_appointments:
        st.info("No appointments match the current filters")
        return
    
    # Display appointments
    for appointment in filtered_appointments:
        # Initialize session state variables for modal visibility
        if f"show_appointment_details_{appointment['id']}" not in st.session_state:
            st.session_state[f"show_appointment_details_{appointment['id']}"] = False
        if f"confirm_delete_apt_{appointment['id']}" not in st.session_state:
            st.session_state[f"confirm_delete_apt_{appointment['id']}"] = False
        
        # Get user and hospital details for display
        user_id = appointment.get('user_id')
        hospital_id = appointment.get('hospital_id')
        
        # Create a more detailed appointment card
        with st.expander(f"📅 Appointment #{appointment.get('id')} - {appointment.get('appointment_date', 'N/A')[:16]} ({appointment.get('status', 'unknown').title()})"):
            col1, col2, col3 = st.columns(3)
            
            with col1:
                st.write("**📋 Appointment Details**")
                st.write(f"**ID:** {appointment.get('id', 'N/A')}")
                st.write(f"**Date:** {appointment.get('appointment_date', 'N/A')[:16] if appointment.get('appointment_date') else 'N/A'}")
                st.write(f"**Status:** {appointment.get('status', 'unknown').title()}")
                st.write(f"**Price:** ${appointment.get('price', 0):.2f}" if appointment.get('price') else "**Price:** Not set")
                
                if appointment.get('notes'):
                    st.write(f"**Notes:** {appointment['notes'][:100]}{'...' if len(appointment['notes']) > 100 else ''}")
            
            with col2:
                st.write("**👤 Patient Information**")
                st.write(f"**Patient ID:** {user_id}")
                
                # Try to get user details (simplified - in real implementation, you'd have a proper join)
                users = get_users()
                patient = next((user for user in users if user['id'] == user_id), None)
                if patient:
                    st.write(f"**Name:** {patient.get('first_name', '')} {patient.get('last_name', '')}")
                    st.write(f"**Email:** {patient.get('email', 'N/A')}")
                    st.write(f"**Type:** {patient.get('user_type', 'N/A').replace('_', ' ').title()}")
                    st.write(f"**Phone:** {patient.get('phone', 'N/A')}")
                else:
                    st.write("**Name:** User not found")
                    st.write("**Email:** N/A")
                    st.write("**Type:** N/A")
            
            with col3:
                st.write("**🏥 Hospital Information**")
                st.write(f"**Hospital ID:** {hospital_id}")
                
                # Try to get hospital details
                hospitals = get_hospitals()
                hospital = next((hosp for hosp in hospitals if hosp['id'] == hospital_id), None)
                if hospital:
                    st.write(f"**Name:** {hospital.get('name', 'N/A')}")
                    st.write(f"**City:** {hospital.get('city', 'N/A')}")
                    st.write(f"**Phone:** {hospital.get('phone', 'N/A')}")
                    st.write(f"**Email:** {hospital.get('email', 'N/A')}")
                else:
                    st.write("**Name:** Hospital not found")
                    st.write("**City:** N/A")
                    st.write("**Phone:** N/A")
            
            # Action buttons
            st.markdown("---")
            st.write("**🔧 Actions**")
            
            action_col1, action_col2, action_col3, action_col4, action_col5 = st.columns(5)
            
            with action_col1:
                if appointment.get('status') == 'pending':
                    if st.button("✅ Confirm", key=f"confirm_apt_{appointment['id']}"):
                        if update_appointment_status(appointment['id'], 'confirmed'):
                            st.success("Appointment confirmed!")
                            st.rerun()
            
            with action_col2:
                if appointment.get('status') in ['pending', 'confirmed']:
                    if st.button("✅ Complete", key=f"complete_apt_{appointment['id']}"):
                        if update_appointment_status(appointment['id'], 'completed'):
                            st.success("Appointment completed!")
                            st.rerun()
            
            with action_col3:
                if appointment.get('status') in ['pending', 'confirmed']:
                    if st.button("❌ Cancel", key=f"cancel_apt_{appointment['id']}"):
                        if update_appointment_status(appointment['id'], 'cancelled'):
                            st.success("Appointment cancelled!")
                            st.rerun()
            
            with action_col4:
                if st.button("👁️ Details", key=f"view_apt_{appointment['id']}"):
                    st.session_state[f"show_appointment_details_{appointment['id']}"] = True
                    st.rerun()
            
            with action_col5:
                if st.button("🗑️ Delete", key=f"delete_apt_{appointment['id']}"):
                    if st.session_state.get(f"confirm_delete_apt_{appointment['id']}", False):
                        if delete_appointment(appointment['id']):
                            st.success("Appointment deleted!")
                            st.rerun()
                    else:
                        st.session_state[f"confirm_delete_apt_{appointment['id']}"] = True
                        st.warning("Click again to confirm deletion")
            
            # Detailed view modal
            if st.session_state.get(f"show_appointment_details_{appointment['id']}", False):
                st.markdown("---")
                st.subheader(f"🔍 Detailed View - Appointment #{appointment['id']}")
                
                detail_col1, detail_col2 = st.columns(2)
                
                with detail_col1:
                    st.write("**📅 Appointment Information**")
                    st.write(f"**ID:** {appointment.get('id')}")
                    st.write(f"**Date & Time:** {appointment.get('appointment_date', 'N/A')}")
                    st.write(f"**Status:** {appointment.get('status', 'unknown').title()}")
                    st.write(f"**Price:** ${appointment.get('price', 0):.2f}" if appointment.get('price') else "Price: Not set")
                    st.write(f"**Service ID:** {appointment.get('service_id', 'N/A')}")
                    st.write(f"**Created:** {appointment.get('created_at', 'N/A')[:16] if appointment.get('created_at') else 'N/A'}")
                    st.write(f"**Updated:** {appointment.get('updated_at', 'N/A')[:16] if appointment.get('updated_at') else 'N/A'}")
                
                with detail_col2:
                    st.write("**📝 Additional Information**")
                    if appointment.get('notes'):
                        st.write(f"**Notes:** {appointment['notes']}")
                    else:
                        st.write("**Notes:** No notes available")
                    
                    # Payment information
                    payments = get_all_payments()
                    appointment_payments = [p for p in payments if p.get('appointment_id') == appointment['id']]
                    if appointment_payments:
                        st.write("**💳 Payment Status:**")
                        for payment in appointment_payments:
                            st.write(f"- Amount: ${payment.get('amount', 0):.2f}")
                            st.write(f"- Status: {payment.get('status', 'unknown').title()}")
                            st.write(f"- Method: {payment.get('payment_method', 'N/A')}")
                            st.write(f"- Gateway: {payment.get('payment_gateway', 'N/A')}")
                            st.write(f"- Transaction ID: {payment.get('transaction_id', 'N/A')}")
                            st.write(f"- Gateway Reference: {payment.get('gateway_reference', 'N/A')}")
                            st.write(f"- Gateway Txn ID: {payment.get('gateway_transaction_id', 'N/A')}")
                            st.write(f"- Auth Code: {payment.get('authorization_code', 'N/A')}")
                            payment_date = payment.get('payment_date')
                            if payment_date:
                                st.write(f"**Payment Date:** {datetime.fromisoformat(payment_date).strftime('%Y-%m-%d %H:%M')}")
                            else:
                                st.write(f"**Payment Date:** N/A")
                    else:
                        st.write("**💳 Payment Status:** No payments found")
                
                if st.button("Close Details", key=f"close_apt_details_{appointment['id']}"):
                    st.session_state[f"show_appointment_details_{appointment['id']}"] = False
                    st.rerun()
    
    # Appointment Statistics
    st.markdown("---")
    st.subheader("📊 Appointment Statistics")
    
    if filtered_appointments:
        # Status distribution
        status_counts = {}
        for apt in filtered_appointments:
            status = apt.get('status', 'unknown')
            status_counts[status] = status_counts.get(status, 0) + 1
        
        # Create a simple chart
        col1, col2 = st.columns(2)
        
        with col1:
            st.write("**Status Distribution:**")
            for status, count in status_counts.items():
                percentage = (count / len(filtered_appointments)) * 100
                st.write(f"- {status.title()}: {count} ({percentage:.1f}%)")
        
        with col2:
            # Revenue information
            total_revenue = sum(apt.get('price', 0) for apt in filtered_appointments if apt.get('price'))
            avg_price = total_revenue / len(filtered_appointments) if filtered_appointments else 0
            
            st.write("**Financial Summary:**")
            st.write(f"- Total Revenue: ${total_revenue:.2f}")
            st.write(f"- Average Price: ${avg_price:.2f}")
            st.write(f"- Paid Appointments: {len([apt for apt in filtered_appointments if apt.get('price', 0) > 0])}")

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
    col1, col2, col3, col4, col5 = st.columns(5)
    with col1:
        user_type_filter = st.selectbox("Filter by Type", ["All"] + list(df['user_type'].unique()))
    with col2:
        status_filter = st.selectbox("Filter by Status", ["All", "Active", "Inactive"])
    with col3:
        verified_filter = st.selectbox("Filter by Verification", ["All", "Verified", "Unverified"])
    with col4:
        profile_completion_filter = st.selectbox("Filter by Profile", ["All", "Complete", "Incomplete"])
    with col5:
        search_term = st.text_input("Search by name/email")
    
    # Apply filters
    filtered_df = df.copy()
    if user_type_filter != "All":
        filtered_df = filtered_df[filtered_df['user_type'] == user_type_filter]
    if status_filter != "All":
        filtered_df = filtered_df[filtered_df['is_active'] == (status_filter == "Active")]
    if verified_filter != "All":
        filtered_df = filtered_df[filtered_df['is_verified'] == (verified_filter == "Verified")]
    if profile_completion_filter != "All":
        filtered_df = filtered_df[filtered_df['profile_completed'] == (profile_completion_filter == "Complete")]
    if search_term:
        filtered_df = filtered_df[
            filtered_df['first_name'].str.contains(search_term, case=False, na=False) |
            filtered_df['last_name'].str.contains(search_term, case=False, na=False) |
            filtered_df['email'].str.contains(search_term, case=False, na=False)
        ]
    
    # Statistics
    total_users = len(df)
    completed_profiles = len(df[df['profile_completed'] == True])
    incomplete_profiles = total_users - completed_profiles
    verified_users = len(df[df['is_verified'] == True])
    
    col1, col2, col3, col4 = st.columns(4)
    with col1:
        st.metric("Total Users", total_users)
    with col2:
        st.metric("Complete Profiles", completed_profiles, f"{completed_profiles/total_users*100:.1f}%")
    with col3:
        st.metric("Incomplete Profiles", incomplete_profiles, f"{incomplete_profiles/total_users*100:.1f}%")
    with col4:
        st.metric("Verified Users", verified_users, f"{verified_users/total_users*100:.1f}%")
    
    st.subheader(f"Users ({len(filtered_df)})")
    
    for _, user in filtered_df.iterrows():
        # Initialize session state variables before creating widgets
        if f"confirm_delete_{user['id']}" not in st.session_state:
            st.session_state[f"confirm_delete_{user['id']}"] = False
        
        with st.expander(f"{user['first_name']} {user['last_name']} - {user['email']} ({user['user_type']})"):
            # Profile Picture and Basic Info
            col1, col2 = st.columns([1, 2])
            
            with col1:
                # Display profile picture
                if user.get('profile_picture'):
                    try:
                        st.image(user['profile_picture'], width=120, caption="Profile Picture")
                    except:
                        st.write("⚠️ Could not load profile picture")
                else:
                    st.write("📷 No profile picture")
                
                # Profile completion status
                profile_completed = user.get('profile_completed', False)
                completion_status = "✅ Complete" if profile_completed else "❌ Incomplete"
                st.write(f"**Profile Status:** {completion_status}")
            
            with col2:
                # Basic Information
                st.write(f"**Name:** {user['first_name']} {user['last_name']}")
                st.write(f"**Email:** {user['email']}")
                st.write(f"**Type:** {user['user_type'].replace('_', ' ').title()}")
                st.write(f"**Phone:** {user.get('phone', 'N/A')}")
                st.write(f"**Gender:** {user.get('gender', 'N/A')}")
                if user.get('date_of_birth'):
                    st.write(f"**Date of Birth:** {user['date_of_birth'][:10]}")
            
            # Detailed Profile Information
            st.markdown("---")
            col3, col4 = st.columns(2)
            
            with col3:
                st.subheader("📍 Location Information")
                st.write(f"**Address:** {user.get('address', 'N/A')}")
                st.write(f"**City:** {user.get('city', 'N/A')}")
                st.write(f"**State:** {user.get('state', 'N/A')}")
                st.write(f"**Country:** {user.get('country', 'N/A')}")
                st.write(f"**Postal Code:** {user.get('postal_code', 'N/A')}")
            
            with col4:
                st.subheader("📝 Additional Information")
                if user.get('bio'):
                    st.write(f"**Bio:** {user['bio']}")
                else:
                    st.write("**Bio:** No bio provided")
                
                st.write(f"**Created:** {user['created_at'][:10]}")
                st.write(f"**Last Updated:** {user['updated_at'][:10]}")
            
            # Account Status and Actions
            st.markdown("---")
            col5, col6, col7 = st.columns(3)
            
            with col5:
                status_class = "status-active" if user['is_active'] else "status-inactive"
                st.markdown(f"**Account Status:** <span class='{status_class}'>{'Active' if user['is_active'] else 'Inactive'}</span>", unsafe_allow_html=True)
                
                verified_class = "status-verified" if user['is_verified'] else "status-unverified"
                st.markdown(f"**Verification:** <span class='{verified_class}'>{'Verified' if user['is_verified'] else 'Unverified'}</span>", unsafe_allow_html=True)
            
            with col6:
                # Profile completion percentage calculation
                completed_fields = 0
                total_fields = 0
                
                # Basic fields
                total_fields += 4  # firstName, lastName, email, userType
                completed_fields += 4
                
                # Profile fields
                total_fields += 1  # phone
                if user.get('phone'): completed_fields += 1
                
                total_fields += 1  # dateOfBirth
                if user.get('date_of_birth'): completed_fields += 1
                
                total_fields += 1  # gender
                if user.get('gender'): completed_fields += 1
                
                total_fields += 1  # profilePicture
                if user.get('profile_picture'): completed_fields += 1
                
                total_fields += 1  # bio
                if user.get('bio'): completed_fields += 1
                
                # Location fields
                total_fields += 1  # address
                if user.get('address'): completed_fields += 1
                
                total_fields += 1  # city
                if user.get('city'): completed_fields += 1
                
                total_fields += 1  # state
                if user.get('state'): completed_fields += 1
                
                total_fields += 1  # country
                if user.get('country'): completed_fields += 1
                
                total_fields += 1  # postalCode
                if user.get('postal_code'): completed_fields += 1
                
                completion_percentage = (completed_fields / total_fields) * 100
                st.write(f"**Profile Completion:** {completion_percentage:.1f}%")
                
                # Progress bar
                st.progress(completion_percentage / 100)
            
            with col7:
                col7a, col7b = st.columns(2)
                
                with col7a:
                    verify_text = "Unverify" if user['is_verified'] else "Verify"
                    if st.button(verify_text, key=f"verify_user_{user['id']}"):
                        new_status = not user['is_verified']
                        if verify_user(user['id'], new_status):
                            st.success(f"User {'verified' if new_status else 'unverified'}!")
                            st.rerun()
                
                with col7b:
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
    
    # Add tabs for different views
    tab1, tab2 = st.tabs(["👥 By User", "📋 All Records"])
    
    with tab1:
        users = get_users()
        donor_surrogate_users = [user for user in users if user['user_type'] in ['sperm_donor', 'egg_donor', 'surrogate']]
        
        if not donor_surrogate_users:
            st.info("No donors or surrogates found")
            return
        
        st.subheader(f"Medical Records by User ({len(donor_surrogate_users)} users)")
        
        for user in donor_surrogate_users:
            with st.expander(f"📋 {user['first_name']} {user['last_name']} - {user['user_type'].replace('_', ' ').title()}"):
                medical_records = get_user_medical_records(user['id'])
                
                if not medical_records:
                    st.info("No medical records submitted yet")
                    continue
                
                st.write(f"**User:** {user['first_name']} {user['last_name']} ({user['email']})")
                st.write(f"**Type:** {user['user_type'].replace('_', ' ').title()}")
                st.write(f"**Total Records:** {len(medical_records)}")
                
                for i, record in enumerate(medical_records):
                    display_medical_record_card(record, user, i)
    
    with tab2:
        st.subheader("All Medical Records")
        
        # Add search and filters
        search_term = st.text_input("🔍 Search by user name or file name", placeholder="Enter search term...")
        
        col1, col2, col3, col4 = st.columns(4)
        with col1:
            status_filter = st.selectbox("Filter by Status", ["All", "Verified", "Unverified"])
        with col2:
            record_type_filter = st.selectbox("Filter by Type", ["All", "LICENSE", "CERTIFICATION", "DIPLOMA", "IDENTIFICATION", "MEDICAL_HISTORY", "LAB_RESULTS", "OTHER"])
        with col3:
            user_type_filter = st.selectbox("Filter by User Type", ["All", "sperm_donor", "egg_donor", "surrogate"])
        with col4:
            sort_by = st.selectbox("Sort by", ["Newest First", "Oldest First", "File Name", "User Name"])
        
        medical_records = get_all_medical_records()
        
        if not medical_records:
            st.info("No medical records found")
            return
        
        # Apply filters
        filtered_records = medical_records
        users = get_users()
        
        # Apply status filter
        if status_filter != "All":
            is_verified = status_filter == "Verified"
            filtered_records = [r for r in filtered_records if r.get('is_verified', False) == is_verified]
        
        # Apply record type filter
        if record_type_filter != "All":
            filtered_records = [r for r in filtered_records if r.get('record_type') == record_type_filter]
        
        # Apply user type filter
        if user_type_filter != "All":
            user_ids_by_type = [u['id'] for u in users if u['user_type'] == user_type_filter]
            filtered_records = [r for r in filtered_records if r.get('user_id') in user_ids_by_type]
        
        # Apply search filter
        if search_term:
            search_lower = search_term.lower()
            filtered_records = [r for r in filtered_records if 
                search_lower in r.get('file_name', '').lower() or
                any(search_lower in f"{u['first_name']} {u['last_name']}".lower() 
                    for u in users if u['id'] == r.get('user_id'))]
        
        # Apply sorting
        if sort_by == "Newest First":
            filtered_records.sort(key=lambda x: x.get('created_at', ''), reverse=True)
        elif sort_by == "Oldest First":
            filtered_records.sort(key=lambda x: x.get('created_at', ''))
        elif sort_by == "File Name":
            filtered_records.sort(key=lambda x: x.get('file_name', ''))
        elif sort_by == "User Name":
            filtered_records.sort(key=lambda x: 
                next((f"{u['first_name']} {u['last_name']}" for u in users if u['id'] == x.get('user_id')), ''))
        
        st.write(f"**Showing {len(filtered_records)} of {len(medical_records)} records**")
        
        # Bulk actions
        if filtered_records:
            st.subheader("Bulk Actions")
            col1, col2, col3 = st.columns(3)
            
            with col1:
                if st.button("✅ Verify All Unverified", key="bulk_verify"):
                    unverified_records = [r for r in filtered_records if not r.get('is_verified', False)]
                    success_count = 0
                    for record in unverified_records:
                        if verify_medical_record(record['id'], True, "Bulk verified by admin"):
                            success_count += 1
                    st.success(f"Successfully verified {success_count} records!")
                    st.rerun()
            
            with col2:
                if st.button("❌ Reject All Unverified", key="bulk_reject"):
                    unverified_records = [r for r in filtered_records if not r.get('is_verified', False)]
                    success_count = 0
                    for record in unverified_records:
                        if verify_medical_record(record['id'], False, "Bulk rejected by admin"):
                            success_count += 1
                    st.success(f"Successfully rejected {success_count} records!")
                    st.rerun()
            
            with col3:
                if st.button("🔄 Refresh", key="refresh_records"):
                    st.rerun()
        
        # Display records with user info
        for i, record in enumerate(filtered_records):
            user = next((u for u in users if u['id'] == record.get('user_id')), None)
            if user:
                display_medical_record_card(record, user, i)

def display_medical_record_card(record, user, index):
    """Display a medical record card with file viewing capabilities"""
    with st.container():
        st.markdown('<div class="medical-record-card">', unsafe_allow_html=True)
        
        # Record information
        col1, col2, col3, col4 = st.columns([2, 1, 1, 1])
        
        with col1:
            st.write(f"**File:** {record.get('file_name', 'Unknown')}")
            st.write(f"**Type:** {record.get('record_type', 'other').replace('_', ' ').title()}")
            st.write(f"**User:** {user['first_name']} {user['last_name']} ({user['user_type'].replace('_', ' ').title()})")
            st.write(f"**Uploaded:** {record.get('created_at', '')[:10]}")
            if record.get('description'):
                st.write(f"**Description:** {record.get('description')}")
        
        with col2:
            verification_status = record.get('is_verified', False)
            status_class = "status-verified" if verification_status else "status-unverified"
            status_text = "Verified" if verification_status else "Unverified"
            st.markdown(f"**Status:** <span class='{status_class}'>{status_text}</span>", unsafe_allow_html=True)
            
            if record.get('verified_by'):
                st.write(f"**Verified by:** User ID {record.get('verified_by')}")
            if record.get('verified_at'):
                st.write(f"**Verified at:** {record.get('verified_at')[:10]}")
        
        with col3:
            # File viewing section
            st.write("**📄 File Preview**")
            file_url = get_medical_record_file_url(record['id'])
            file_ext = record.get('file_name', '').split('.')[-1].lower() if record.get('file_name') else ''
            file_size = record.get('file_size', 0)
            
            # Display file info
            st.write(f"**Type:** {file_ext.upper()}")
            st.write(f"**Size:** {file_size / 1024:.1f} KB")
            
            # File viewing options
            if file_ext in ['jpg', 'jpeg', 'png']:
                # For images, show a preview
                try:
                    response = requests.get(file_url, headers=get_headers())
                    if response.status_code == 200:
                        st.image(response.content, caption=record.get('file_name'), use_column_width=True)
                    else:
                        st.error("Could not load image")
                        st.markdown(f"[🔗 Open Image]({file_url})", unsafe_allow_html=True)
                except Exception as e:
                    st.error(f"Error loading image: {str(e)}")
                    st.markdown(f"[🔗 Open Image]({file_url})", unsafe_allow_html=True)
            elif file_ext == 'pdf':
                # For PDFs, provide a direct link
                st.markdown(f"[📄 View PDF]({file_url})", unsafe_allow_html=True)
            else:
                # For other files, provide download link
                st.markdown(f"[📄 Download {file_ext.upper()}]({file_url})", unsafe_allow_html=True)
        
        with col4:
            # Verification actions
            # Create a truly unique key using record ID, index, and Python's id() for the record object
            # This ensures uniqueness even if the same record appears in multiple tabs
            unique_key_suffix = f"{record['id']}_{index}_{id(record)}"
            
            if not verification_status:
                if st.button("✅ Verify", key=f"verify_record_{unique_key_suffix}"):
                    if verify_medical_record(record['id'], True, "Verified by admin"):
                        st.success("Record verified!")
                        st.rerun()
            
            if st.button("❌ Reject", key=f"reject_record_{unique_key_suffix}"):
                if verify_medical_record(record['id'], False, "Rejected by admin"):
                    st.success("Record rejected!")
                    st.rerun()
            
            # Add delete button for rejected records
            if not verification_status:  # Show delete button for rejected records
                st.markdown("---")  # Add a separator
                if st.button("🗑️ Delete", key=f"delete_record_{unique_key_suffix}", type="secondary"):
                    # Add confirmation dialog
                    if st.session_state.get(f"confirm_delete_{unique_key_suffix}", False):
                        if delete_medical_record(record['id']):
                            st.success("Record deleted successfully!")
                            st.rerun()
                        else:
                            st.error("Failed to delete record")
                    else:
                        st.session_state[f"confirm_delete_{unique_key_suffix}"] = True
                        st.warning("Click delete again to confirm")
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
                postal_code = st.text_input("Postal Code")
            
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
                        "postal_code": postal_code,
                        "description": description,
                        "specialties": [],
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
    st.markdown('<h1 class="main-header">👨‍⚕️ Complete Doctor Management</h1>', unsafe_allow_html=True)
    
    tab1, tab2, tab3 = st.tabs(["👨‍⚕️ All Doctors", "➕ Add Doctor", "🏥 Add to Hospital"])
    
    with tab1:
        st.subheader("All Doctors")
        
        doctors = get_all_doctors()
        if not doctors:
            st.info("No doctors found")
        else:
            # Search and filter
            col1, col2 = st.columns(2)
            with col1:
                search_term = st.text_input("🔍 Search doctors by name or email")
            with col2:
                status_filter = st.selectbox("Filter by Status", ["All", "Active", "Inactive"])
            
            # Filter doctors
            filtered_doctors = doctors
            if search_term:
                filtered_doctors = [
                    doctor for doctor in filtered_doctors 
                    if search_term.lower() in f"{doctor.get('first_name', '')} {doctor.get('last_name', '')} {doctor.get('email', '')}".lower()
                ]
            if status_filter != "All":
                filtered_doctors = [
                    doctor for doctor in filtered_doctors 
                    if doctor.get('is_active', False) == (status_filter == "Active")
                ]
            
            st.write(f"**Total Doctors:** {len(filtered_doctors)}")
            
            for doctor in filtered_doctors:
                # Initialize session state variables for modal visibility
                if f"show_doctor_details_{doctor['id']}" not in st.session_state:
                    st.session_state[f"show_doctor_details_{doctor['id']}"] = False
                if f"show_edit_doctor_{doctor['id']}" not in st.session_state:
                    st.session_state[f"show_edit_doctor_{doctor['id']}"] = False
                if f"confirm_delete_doctor_{doctor['id']}" not in st.session_state:
                    st.session_state[f"confirm_delete_doctor_{doctor['id']}"] = False
                
                with st.expander(f"Dr. {doctor.get('first_name', '')} {doctor.get('last_name', '')} - {doctor.get('email', '')}"):
                    col1, col2, col3 = st.columns(3)
                    
                    with col1:
                        st.write(f"**Name:** Dr. {doctor.get('first_name', '')} {doctor.get('last_name', '')}")
                        st.write(f"**Email:** {doctor.get('email', 'N/A')}")
                        st.write(f"**Phone:** {doctor.get('phone', 'N/A')}")
                        st.write(f"**Created:** {doctor.get('created_at', '')[:10] if doctor.get('created_at') else 'N/A'}")
                    
                    with col2:
                        status_class = "status-active" if doctor.get('is_active', False) else "status-inactive"
                        st.markdown(f"**Status:** <span class='{status_class}'>{'Active' if doctor.get('is_active', False) else 'Inactive'}</span>", unsafe_allow_html=True)
                        
                        verified_class = "status-verified" if doctor.get('is_verified', False) else "status-unverified"
                        st.markdown(f"**Verified:** <span class='{verified_class}'>{'Yes' if doctor.get('is_verified', False) else 'No'}</span>", unsafe_allow_html=True)
                        
                        if doctor.get('bio'):
                            st.write(f"**Bio:** {doctor['bio'][:100]}{'...' if len(doctor['bio']) > 100 else ''}")
                    
                    with col3:
                        col3a, col3b, col3c = st.columns(3)
                        
                        with col3a:
                            if st.button("👁️ View", key=f"view_doctor_{doctor['id']}"):
                                st.session_state[f"show_doctor_details_{doctor['id']}"] = True
                                st.rerun()
                        
                        with col3b:
                            if st.button("✏️ Edit", key=f"edit_doctor_{doctor['id']}"):
                                st.session_state[f"show_edit_doctor_{doctor['id']}"] = True
                                st.rerun()
                        
                        with col3c:
                            if st.button("🗑️ Delete", key=f"delete_doctor_{doctor['id']}"):
                                if st.session_state.get(f"confirm_delete_doctor_{doctor['id']}", False):
                                    if delete_doctor(doctor['id']):
                                        st.success("Doctor deleted successfully!")
                                        st.rerun()
                                else:
                                    st.session_state[f"confirm_delete_doctor_{doctor['id']}"] = True
                                    st.warning("Click again to confirm deletion")
                    
                    # View Doctor Details Modal
                    if st.session_state.get(f"show_doctor_details_{doctor['id']}", False):
                        st.markdown("---")
                        st.subheader(f"👁️ Doctor Details: Dr. {doctor.get('first_name', '')} {doctor.get('last_name', '')}")
                        
                        detail_col1, detail_col2 = st.columns(2)
                        with detail_col1:
                            st.write(f"**Full Name:** Dr. {doctor.get('first_name', '')} {doctor.get('last_name', '')}")
                            st.write(f"**Email:** {doctor.get('email', 'N/A')}")
                            st.write(f"**Phone:** {doctor.get('phone', 'N/A')}")
                            st.write(f"**User Type:** {doctor.get('user_type', 'N/A')}")
                        
                        with detail_col2:
                            st.write(f"**Active:** {'Yes' if doctor.get('is_active', False) else 'No'}")
                            st.write(f"**Verified:** {'Yes' if doctor.get('is_verified', False) else 'No'}")
                            st.write(f"**Profile Completed:** {'Yes' if doctor.get('profile_completed', False) else 'No'}")
                            st.write(f"**Created:** {doctor.get('created_at', 'N/A')}")
                        
                        if doctor.get('bio'):
                            st.write(f"**Bio:** {doctor['bio']}")
                        
                        if st.button("Close Details", key=f"close_view_{doctor['id']}"):
                            st.session_state[f"show_doctor_details_{doctor['id']}"] = False
                            st.rerun()
                    
                    # Edit Doctor Modal
                    if st.session_state.get(f"show_edit_doctor_{doctor['id']}", False):
                        st.markdown("---")
                        st.subheader(f"✏️ Edit Doctor: Dr. {doctor.get('first_name', '')} {doctor.get('last_name', '')}")
                        
                        with st.form(f"edit_doctor_form_{doctor['id']}"):
                            edit_col1, edit_col2 = st.columns(2)
                            
                            with edit_col1:
                                edit_first_name = st.text_input("First Name*", value=doctor.get('first_name', ''))
                                edit_last_name = st.text_input("Last Name*", value=doctor.get('last_name', ''))
                                edit_email = st.text_input("Email*", value=doctor.get('email', ''))
                            
                            with edit_col2:
                                edit_phone = st.text_input("Phone*", value=doctor.get('phone', ''))
                                edit_specialization = st.text_input("Specialization", value="General Medicine")
                                edit_license_number = st.text_input("License Number", value="LIC123456")
                            
                            edit_bio = st.text_area("Bio", value=doctor.get('bio', ''))
                            
                            edit_col3, edit_col4 = st.columns(2)
                            with edit_col3:
                                edit_submit = st.form_submit_button("💾 Update Doctor", use_container_width=True)
                            with edit_col4:
                                edit_cancel = st.form_submit_button("❌ Cancel", use_container_width=True)
                            
                            if edit_submit:
                                if edit_first_name and edit_last_name and edit_email and edit_phone:
                                    edit_doctor_data = {
                                        "first_name": edit_first_name,
                                        "last_name": edit_last_name,
                                        "email": edit_email,
                                        "phone": edit_phone,
                                        "specialization": edit_specialization,
                                        "license_number": edit_license_number,
                                        "years_experience": 5,
                                        "rating": 4.0,
                                        "bio": edit_bio
                                    }
                                    
                                    if update_doctor(doctor['id'], edit_doctor_data):
                                        st.success("Doctor updated successfully!")
                                        st.session_state[f"show_edit_doctor_{doctor['id']}"] = False
                                        st.rerun()
                                else:
                                    st.error("Please fill in all required fields marked with *")
                            
                            if edit_cancel:
                                st.session_state[f"show_edit_doctor_{doctor['id']}"] = False
                                st.rerun()
    
    with tab2:
        st.subheader("Add New Doctor")
        
        with st.form("add_new_doctor_form"):
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
            
            submit = st.form_submit_button("➕ Add Doctor", use_container_width=True)
            
            if submit:
                if first_name and last_name and email and phone and specialization and license_number:
                    # For standalone doctor creation, we'll use the hospital endpoint with the first available hospital
                    hospitals = get_hospitals()
                    if hospitals:
                        hospital_id = hospitals[0]['id']  # Use first hospital as default
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
                        st.error("No hospitals found. Please add a hospital first.")
                else:
                    st.error("Please fill in all required fields marked with *")
    
    with tab3:
        st.subheader("Add Doctor to Specific Hospital")
        
        hospitals = get_hospitals()
        if not hospitals:
            st.info("No hospitals found. Please add hospitals first.")
            return
        
        hospital_options = {f"{hospital['name']} - {hospital['city']}": hospital['id'] for hospital in hospitals}
        selected_hospital_name = st.selectbox("Select Hospital", list(hospital_options.keys()))
        
        if selected_hospital_name:
            hospital_id = hospital_options[selected_hospital_name]
            
            with st.form("add_doctor_to_hospital_form"):
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
                
                submit = st.form_submit_button("🏥 Add Doctor to Hospital", use_container_width=True)
                
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
                            st.success(f"Doctor added to {selected_hospital_name} successfully!")
                            st.rerun()
                        else:
                            st.error("Failed to add doctor")
                    else:
                        st.error("Please fill in all required fields marked with *")

def show_services_management():
    st.markdown('<h1 class="main-header">🔧 Complete Services Management</h1>', unsafe_allow_html=True)
    
    tab1, tab2, tab3 = st.tabs(["🔧 All Services", "➕ Add Service", "📊 Service Statistics"])
    
    with tab1:
        st.subheader("All Services")
        
        services = get_all_services()
        if not services:
            st.info("No services found")
        else:
            # Search and filter
            col1, col2, col3 = st.columns(3)
            with col1:
                search_term = st.text_input("🔍 Search services by name")
            with col2:
                service_type_filter = st.selectbox("Filter by Type", ["All", "sperm_donation", "egg_donation", "surrogacy"])
            with col3:
                status_filter = st.selectbox("Filter by Status", ["All", "Active", "Inactive"])
            
            # Filter services
            filtered_services = services
            if search_term:
                filtered_services = [
                    service for service in filtered_services 
                    if search_term.lower() in service.get('name', '').lower()
                ]
            if service_type_filter != "All":
                filtered_services = [
                    service for service in filtered_services 
                    if service.get('service_type') == service_type_filter
                ]
            if status_filter != "All":
                filtered_services = [
                    service for service in filtered_services 
                    if service.get('is_active', False) == (status_filter == "Active")
                ]
            
            st.write(f"**Total Services:** {len(filtered_services)}")
            
            for service in filtered_services:
                # Skip services without valid ID
                if not service or 'id' not in service or service['id'] is None:
                    st.warning("Skipping service with invalid ID")
                    continue
                
                # Initialize session state variables for modal visibility
                if f"show_view_modal_{service['id']}" not in st.session_state:
                    st.session_state[f"show_view_modal_{service['id']}"] = False
                if f"show_edit_modal_{service['id']}" not in st.session_state:
                    st.session_state[f"show_edit_modal_{service['id']}"] = False
                if f"confirm_delete_service_{service['id']}" not in st.session_state:
                    st.session_state[f"confirm_delete_service_{service['id']}"] = False
                
                with st.expander(f"🔧 {service.get('name', 'Unknown Service')} - {service.get('service_type', 'unknown').replace('_', ' ').title()}"):
                    col1, col2, col3 = st.columns(3)
                    
                    with col1:
                        st.write(f"**Name:** {service.get('name', 'N/A')}")
                        st.write(f"**Type:** {service.get('service_type', 'unknown').replace('_', ' ').title()}")
                        st.write(f"**Price:** ${service.get('price', 0):.2f}")
                        st.write(f"**Created:** {service.get('created_at', '')[:10] if service.get('created_at') else 'N/A'}")
                    
                    with col2:
                        status_class = "status-active" if service.get('is_active', False) else "status-inactive"
                        st.markdown(f"**Status:** <span class='{status_class}'>{'Active' if service.get('is_active', False) else 'Inactive'}</span>", unsafe_allow_html=True)
                        
                        if service.get('description'):
                            st.write(f"**Description:** {service['description'][:100]}{'...' if len(service['description']) > 100 else ''}")
                        
                        st.write(f"**Updated:** {service.get('updated_at', '')[:10] if service.get('updated_at') else 'N/A'}")
                    
                    with col3:
                        col3a, col3b, col3c = st.columns(3)
                        
                        with col3a:
                            if st.button("👁️ View", key=f"view_service_{service['id']}"):
                                st.session_state[f"show_view_modal_{service['id']}"] = True
                                st.rerun()
                        
                        with col3b:
                            if st.button("✏️ Edit", key=f"edit_service_{service['id']}"):
                                st.session_state[f"show_edit_modal_{service['id']}"] = True
                                st.rerun()
                        
                        with col3c:
                            if st.button("🗑️ Delete", key=f"delete_service_{service['id']}"):
                                if st.session_state.get(f"confirm_delete_service_{service['id']}", False):
                                    if delete_service(service['id']):
                                        st.success("Service deleted successfully!")
                                        st.rerun()
                                else:
                                    st.session_state[f"confirm_delete_service_{service['id']}"] = True
                                    st.warning("Click again to confirm deletion")
                                    st.rerun()
                    
                    # View Service Details Modal
                    if st.session_state.get(f"show_view_modal_{service['id']}", False):
                        st.markdown("---")
                        st.subheader(f"👁️ Service Details: {service.get('name', 'Unknown Service')}")
                        
                        detail_col1, detail_col2 = st.columns(2)
                        with detail_col1:
                            st.write(f"**Service Name:** {service.get('name', 'N/A')}")
                            st.write(f"**Service Type:** {service.get('service_type', 'unknown').replace('_', ' ').title()}")
                            st.write(f"**Price:** ${service.get('price', 0):.2f}")
                            st.write(f"**Active:** {'Yes' if service.get('is_active', False) else 'No'}")
                        
                        with detail_col2:
                            st.write(f"**ID:** {service.get('id', 'N/A')}")
                            st.write(f"**Created:** {service.get('created_at', 'N/A')}")
                            st.write(f"**Updated:** {service.get('updated_at', 'N/A')}")
                        
                        if service.get('description'):
                            st.write(f"**Description:** {service['description']}")
                        
                        if st.button("Close Details", key=f"close_view_service_{service['id']}"):
                            st.session_state[f"show_view_modal_{service['id']}"] = False
                            st.rerun()
                    
                    # Edit Service Modal
                    if st.session_state.get(f"show_edit_modal_{service['id']}", False):
                        st.markdown("---")
                        st.subheader(f"✏️ Edit Service: {service.get('name', 'Unknown Service')}")
                        
                        with st.form(f"edit_service_form_{service['id']}"):
                            edit_col1, edit_col2 = st.columns(2)
                            
                            with edit_col1:
                                edit_name = st.text_input("Service Name*", value=service.get('name', ''))
                                edit_service_type = st.selectbox("Service Type*", 
                                    ["sperm_donation", "egg_donation", "surrogacy"], 
                                    index=["sperm_donation", "egg_donation", "surrogacy"].index(service.get('service_type', 'sperm_donation'))
                                )
                                edit_price = st.number_input("Price*", min_value=0.0, value=float(service.get('price', 0)))
                                edit_duration = st.number_input("Duration (minutes)*", min_value=1, value=int(service.get('duration_minutes', 60)))
                            
                            with edit_col2:
                                edit_is_active = st.checkbox("Active", value=service.get('is_active', True))
                            
                            edit_description = st.text_area("Description", value=service.get('description', ''))
                            
                            edit_col3, edit_col4 = st.columns(2)
                            with edit_col3:
                                edit_submit = st.form_submit_button("💾 Update Service", use_container_width=True)
                            with edit_col4:
                                edit_cancel = st.form_submit_button("❌ Cancel", use_container_width=True)
                            
                            if edit_submit:
                                if edit_name and edit_service_type and edit_price >= 0:
                                    edit_service_data = {
                                        "name": edit_name,
                                        "service_type": edit_service_type,
                                        "description": edit_description,
                                        "price": edit_price,
                                        "duration_minutes": edit_duration,
                                        "is_active": edit_is_active
                                    }
                                    
                                    if update_service(service['id'], edit_service_data):
                                        st.success("Service updated successfully!")
                                        st.session_state[f"show_edit_modal_{service['id']}"] = False
                                        st.rerun()
                                else:
                                    st.error("Please fill in all required fields marked with *")
                            
                            if edit_cancel:
                                st.session_state[f"show_edit_modal_{service['id']}"] = False
                                st.rerun()
    
    with tab2:
        st.subheader("Add New Service")
        
        with st.form("add_new_service_form"):
            col1, col2 = st.columns(2)
            
            with col1:
                name = st.text_input("Service Name*")
                service_type = st.selectbox("Service Type*", ["sperm_donation", "egg_donation", "surrogacy"])
                price = st.number_input("Price*", min_value=0.0, value=100.0)
                duration_minutes = st.number_input("Duration (minutes)*", min_value=1, value=60)
            
            with col2:
                is_active = st.checkbox("Active", value=True)
            
            description = st.text_area("Description*")
            
            submit = st.form_submit_button("➕ Add Service", use_container_width=True)
            
            if submit:
                if name and service_type and price >= 0 and description:
                    service_data = {
                        "name": name,
                        "service_type": service_type,
                        "description": description,
                        "price": price,
                        "duration_minutes": duration_minutes,
                        "is_active": is_active
                    }
                    
                    if create_service(service_data):
                        st.success("Service added successfully!")
                        st.rerun()
                    else:
                        st.error("Failed to add service")
                else:
                    st.error("Please fill in all required fields marked with *")
    
    with tab3:
        st.subheader("Service Statistics")
        
        services = get_all_services()
        service_stats = get_service_stats()
        
        if services:
            # Summary metrics
            col1, col2, col3, col4 = st.columns(4)
            
            with col1:
                total_services = len(services)
                st.metric("Total Services", total_services)
            
            with col2:
                active_services = len([s for s in services if s.get('is_active', False)])
                st.metric("Active Services", active_services, delta=f"{active_services/total_services*100:.1f}%" if total_services > 0 else "0%")
            
            with col3:
                inactive_services = len([s for s in services if not s.get('is_active', True)])
                st.metric("Inactive Services", inactive_services, delta=f"{inactive_services/total_services*100:.1f}%" if total_services > 0 else "0%")
            
            with col4:
                avg_price = sum(s.get('price', 0) for s in services) / len(services) if services else 0
                st.metric("Average Price", f"${avg_price:.2f}")
            
            # Service type distribution
            st.markdown("---")
            col1, col2 = st.columns(2)
            
            with col1:
                st.subheader("📊 Service Type Distribution")
                service_type_counts = {}
                for service in services:
                    service_type = service.get('service_type', 'unknown')
                    service_type_counts[service_type] = service_type_counts.get(service_type, 0) + 1
                
                for service_type, count in service_type_counts.items():
                    percentage = (count / len(services)) * 100
                    st.write(f"- {service_type.replace('_', ' ').title()}: {count} ({percentage:.1f}%)")
            
            with col2:
                st.subheader("💰 Price Analysis")
                prices = [s.get('price', 0) for s in services if s.get('price', 0) > 0]
                if prices:
                    min_price = min(prices)
                    max_price = max(prices)
                    st.write(f"- Minimum Price: ${min_price:.2f}")
                    st.write(f"- Maximum Price: ${max_price:.2f}")
                    st.write(f"- Average Price: ${avg_price:.2f}")
                    st.write(f"- Total Services with Price: {len(prices)}")
                else:
                    st.write("No services with pricing information found")
            
            # Recent services
            st.markdown("---")
            st.subheader("🕒 Recently Added Services")
            recent_services = sorted(services, key=lambda x: x.get('created_at', ''), reverse=True)[:5]
            
            for service in recent_services:
                st.write(f"- **{service.get('name', 'Unknown')}** ({service.get('service_type', 'unknown').replace('_', ' ').title()}) - ${service.get('price', 0):.2f} - {service.get('created_at', 'N/A')[:10]}")
        
        else:
            st.info("No services found to display statistics")

def show_payments_management():
    st.markdown('<h1 class="main-header">💳 Payment Management</h1>', unsafe_allow_html=True)
    
    payments = get_all_payments()
    if not payments:
        st.info("No payments found")
        return

    df = pd.DataFrame(payments)
    
    # Debug: Show available columns
    st.write("**Debug Info:** Available columns:", list(df.columns))
    st.write("**Debug Info:** Sample data:", df.head(1).to_dict('records') if len(df) > 0 else "No data")
    
    # Summary metrics
    col1, col2, col3, col4 = st.columns(4)
    with col1:
        st.metric("Total Payments", len(df))
    with col2:
        completed_payments = df[df['status'] == 'completed']['amount'].sum()
        st.metric("Total Revenue", f"${completed_payments:,.2f}")
    with col3:
        pending_count = len(df[df['status'] == 'pending'])
        st.metric("Pending Payments", pending_count)
    with col4:
        failed_count = len(df[df['status'] == 'failed'])
        st.metric("Failed Payments", failed_count)


    # Filters
    st.subheader("🔍 Filter Payments")
    filter_cols = st.columns(4)
    with filter_cols[0]:
        status_filter = st.selectbox("Filter by Status", ["All"] + list(df['status'].unique()))
    with filter_cols[1]:
        # Handle missing payment_gateway column gracefully
        if 'payment_gateway' in df.columns:
            gateway_options = ["All"] + list(df['payment_gateway'].unique())
        else:
            gateway_options = ["All"]
        gateway_filter = st.selectbox("Filter by Gateway", gateway_options)
    with filter_cols[2]:
        search_term = st.text_input("Search by User/Appt ID")
    
    # Apply filters
    filtered_df = df.copy()
    if status_filter != "All":
        filtered_df = filtered_df[filtered_df['status'] == status_filter]
    if gateway_filter != "All" and 'payment_gateway' in filtered_df.columns:
        filtered_df = filtered_df[filtered_df['payment_gateway'] == gateway_filter]
    if search_term:
        filtered_df = filtered_df[
            filtered_df['user_id'].astype(str).str.contains(search_term, case=False, na=False) |
            filtered_df['appointment_id'].astype(str).str.contains(search_term, case=False, na=False)
        ]

    st.subheader(f"📋 Payments ({len(filtered_df)})")

    for _, payment in filtered_df.iterrows():
        # Initialize session state variables for modal visibility
        if f"show_payment_details_{payment['id']}" not in st.session_state:
            st.session_state[f"show_payment_details_{payment['id']}"] = False
        if f"confirm_delete_payment_{payment['id']}" not in st.session_state:
            st.session_state[f"confirm_delete_payment_{payment['id']}"] = False
        
        with st.expander(f"Payment ID: {payment['id']} - Amount: ${payment['amount']:.2f} - Status: {payment['status'].title()}"):
            col1, col2, col3 = st.columns(3)

            with col1:
                st.write(f"**User ID:** {payment['user_id']}")
                st.write(f"**Appointment ID:** {payment.get('appointment_id', 'N/A')}")
                st.write(f"**Amount:** ${payment['amount']:.2f} {payment.get('currency', 'NGN')}")
                
            with col2:
                # Handle missing payment_gateway column gracefully
                if 'payment_gateway' in payment and payment['payment_gateway']:
                    st.write(f"**Gateway:** {payment['payment_gateway'].title()}")
                else:
                    st.write("**Gateway:** N/A")
                st.write(f"**Transaction ID:** {payment.get('transaction_id', 'N/A')}")
                st.write(f"**Gateway Reference:** {payment.get('gateway_reference', 'N/A')}")
                st.write(f"**Gateway Txn ID:** {payment.get('gateway_transaction_id', 'N/A')}")
                st.write(f"**Auth Code:** {payment.get('authorization_code', 'N/A')}")
                st.write(f"**Gateway Response:** {str(payment.get('gateway_response', ''))[:100]}...")
                st.write(f"**Gateway Status:** {payment.get('gateway_response', {}).get('data', {}).get('status', 'N/A')}")
                st.write(f"**Gateway Message:** {payment.get('gateway_response', {}).get('message', 'N/A')}")
                payment_date = payment.get('payment_date')
                if payment_date:
                    st.write(f"**Payment Date:** {datetime.fromisoformat(payment_date).strftime('%Y-%m-%d %H:%M')}")
                else:
                    st.write(f"**Payment Date:** N/A")

            with col3:
                st.write("**Actions**")
                action_cols = st.columns(2)
                with action_cols[0]:
                    if st.button("View Details", key=f"view_payment_{payment['id']}"):
                        st.session_state[f"show_payment_details_{payment['id']}"] = True
                        st.rerun()

                with action_cols[1]:
                    if st.button("🗑️ Delete", key=f"delete_payment_{payment['id']}"):
                        if st.session_state.get(f"confirm_delete_payment_{payment['id']}", False):
                            if delete_payment(payment['id']):
                                st.success("Payment deleted!")
                                st.session_state[f"confirm_delete_payment_{payment['id']}"] = False
                                st.rerun()
                        else:
                            st.session_state[f"confirm_delete_payment_{payment['id']}"] = True
                            st.warning("Click again to confirm deletion.")
                            st.rerun()


            if st.session_state.get(f"show_payment_details_{payment['id']}", False):
                st.markdown("---")
                st.subheader("Full Gateway Response")
                st.json(payment.get('gateway_response', {}))

                # Manual status update
                st.subheader("Update Payment Status")
                status_options = ["pending", "completed", "failed", "refunded", "cancelled"]
                current_status_index = status_options.index(payment['status']) if payment['status'] in status_options else 0
                
                new_status = st.selectbox(
                    "New Status",
                    options=status_options,
                    index=current_status_index,
                    key=f"update_status_select_{payment['id']}"
                )
                if st.button("Update Status", key=f"update_status_btn_{payment['id']}"):
                    if update_payment_status(payment['id'], new_status):
                        st.success(f"Payment status updated to {new_status}")
                        st.session_state[f"show_payment_details_{payment['id']}"] = False
                        st.rerun()
                    else:
                        st.error("Failed to update payment status.")

                if st.button("Close Details", key=f"close_payment_details_{payment['id']}"):
                    st.session_state[f"show_payment_details_{payment['id']}"] = False
                    st.rerun()

            # Refund and Cancel actions
            if payment['status'] == 'completed':
                if st.button(f"Refund Payment {payment['id']}"):
                    # Call backend refund endpoint
                    try:
                        response = requests.post(f"http://localhost:8000/payments/{payment['id']}/refund", headers={"Authorization": f"Bearer {st.session_state['admin_token']}"})
                        st.success(response.json().get('message', 'Refund successful'))
                        st.experimental_rerun()
                    except Exception as e:
                        st.error(f"Refund failed: {e}")
            if payment['status'] in ['pending', 'confirmed']:
                if st.button(f"Cancel Payment {payment['id']}"):
                    # Call backend cancel endpoint
                    try:
                        response = requests.post(f"http://localhost:8000/payments/{payment['id']}/cancel", headers={"Authorization": f"Bearer {st.session_state['admin_token']}"})
                        st.success(response.json().get('message', 'Cancel successful'))
                        st.experimental_rerun()
                    except Exception as e:
                        st.error(f"Cancel failed: {e}")

def show_payment_gateways_management():

    st.markdown('<h1 class="main-header">💳 Payment Gateway Management</h1>', unsafe_allow_html=True)
    
    tab1, tab2, tab3 = st.tabs(["💳 All Gateways", "⚙️ Configure Gateway", "📊 Gateway Statistics"])
    
    with tab1:
        st.subheader("Payment Gateway Status")
        
        gateways = get_payment_gateways()
        if not gateways:
            st.info("No payment gateways configured")
        else:
            for gateway in gateways:
                # Initialize session state variables before creating widgets
                if f"configure_{gateway['gateway']}" not in st.session_state:
                    st.session_state[f"configure_{gateway['gateway']}"] = False
                
                with st.expander(f"💳 {gateway['gateway'].title()} Payment Gateway"):
                    col1, col2, col3 = st.columns(3)
                    
                    with col1:
                        st.write(f"**Gateway:** {gateway['gateway'].title()}")
                        status_class = "status-active" if gateway['is_active'] else "status-inactive"
                        st.markdown(f"**Status:** <span class='{status_class}'>{'Active' if gateway['is_active'] else 'Inactive'}</span>", unsafe_allow_html=True)
                        
                        mode_class = "status-pending" if gateway['is_test_mode'] else "status-verified"
                        st.markdown(f"**Mode:** <span class='{mode_class}'>{'Test' if gateway['is_test_mode'] else 'Live'}</span>", unsafe_allow_html=True)
                    
                    with col2:
                        st.write(f"**Public Key:** {'Configured' if gateway['public_key'] != '***' else 'Not Set'}")
                        st.write(f"**Secret Key:** {'Configured' if gateway['secret_key'] != '***' else 'Not Set'}")
                        st.write(f"**Webhook Secret:** {'Configured' if gateway['webhook_secret'] != '***' else 'Not Set'}")
                        
                        if gateway.get('supported_currencies'):
                            currencies = ', '.join(gateway['supported_currencies'])
                            st.write(f"**Supported Currencies:** {currencies}")
                    
                    with col3:
                        col3a, col3b, col3c = st.columns(3)
                        
                        with col3a:
                            if gateway['is_active']:
                                if st.button("❌ Deactivate", key=f"deactivate_{gateway['gateway']}"):
                                    if deactivate_payment_gateway(gateway['gateway']):
                                        st.success(f"{gateway['gateway'].title()} deactivated!")
                                        st.rerun()
                            else:
                                if st.button("✅ Activate", key=f"activate_{gateway['gateway']}"):
                                    if activate_payment_gateway(gateway['gateway']):
                                        st.success(f"{gateway['gateway'].title()} activated!")
                                        st.rerun()
                        
                        with col3b:
                            if st.button("🧪 Test", key=f"test_{gateway['gateway']}"):
                                with st.spinner("Testing connection..."):
                                    result = test_payment_gateway(gateway['gateway'])
                                    if result['status'] == 'success':
                                        st.success(result['message'])
                                    else:
                                        st.error(result['message'])
                        
                        with col3c:
                            if st.button("⚙️ Configure", key=f"config_{gateway['gateway']}"):
                                st.session_state[f"configure_{gateway['gateway']}"] = True
                                st.rerun()
                    
                    # Configuration Modal
                    if st.session_state.get(f"configure_{gateway['gateway']}", False):
                        st.markdown("---")
                        st.subheader(f"⚙️ Configure {gateway['gateway'].title()}")
                        
                        with st.form(f"config_form_{gateway['gateway']}"):
                            config_col1, config_col2 = st.columns(2)
                            
                            with config_col1:
                                public_key = st.text_input("Public Key*", type="password", help="Your publishable key from the payment gateway")
                                secret_key = st.text_input("Secret Key*", type="password", help="Your secret key from the payment gateway")
                                webhook_secret = st.text_input("Webhook Secret", type="password", help="Webhook secret for verifying callbacks")
                            
                            with config_col2:
                                is_test_mode = st.checkbox("Test Mode", value=gateway.get('is_test_mode', True), help="Enable for testing, disable for live payments")
                                
                                if gateway['gateway'] == 'paystack':
                                    default_currencies = ["NGN", "USD", "GHS", "ZAR"]
                                elif gateway['gateway'] == 'stripe':
                                    default_currencies = ["USD", "EUR", "GBP"]
                                else:
                                    default_currencies = ["NGN", "USD"]
                                
                                currencies_input = st.text_input("Supported Currencies", 
                                    value=", ".join(gateway.get('supported_currencies', default_currencies)),
                                    help="Comma-separated list of currency codes (e.g., NGN, USD, EUR)")
                            
                            config_col3, config_col4 = st.columns(2)
                            with config_col3:
                                config_submit = st.form_submit_button("💾 Save Configuration", use_container_width=True)
                            with config_col4:
                                config_cancel = st.form_submit_button("❌ Cancel", use_container_width=True)
                            
                            if config_submit:
                                if public_key and secret_key:
                                    currencies_list = [c.strip().upper() for c in currencies_input.split(',') if c.strip()]
                                    
                                    config_data = {
                                        "public_key": public_key,
                                        "secret_key": secret_key,
                                        "webhook_secret": webhook_secret,
                                        "is_test_mode": is_test_mode,
                                        "supported_currencies": currencies_list
                                    }
                                    
                                    if update_payment_gateway_config(gateway['gateway'], config_data):
                                        st.success(f"{gateway['gateway'].title()} configuration updated!")
                                        st.session_state[f"configure_{gateway['gateway']}"] = False
                                        st.rerun()
                                else:
                                    st.error("Please provide both public key and secret key")
                            
                            if config_cancel:
                                st.session_state[f"configure_{gateway['gateway']}"] = False
                                st.rerun()
    
    with tab2:
        st.subheader("Add New Payment Gateway")
        
        with st.form("add_gateway_form"):
            col1, col2 = st.columns(2)
            
            with col1:
                gateway_type = st.selectbox("Gateway Type*", ["paystack", "stripe", "flutterwave"])
                public_key = st.text_input("Public Key*", type="password")
                secret_key = st.text_input("Secret Key*", type="password")
            
            with col2:
                webhook_secret = st.text_input("Webhook Secret", type="password")
                is_test_mode = st.checkbox("Test Mode", value=True)
                is_active = st.checkbox("Activate Immediately", value=False)
            
            if gateway_type == 'paystack':
                default_currencies = "NGN, USD, GHS, ZAR"
            elif gateway_type == 'stripe':
                default_currencies = "USD, EUR, GBP"
            else:
                default_currencies = "NGN, USD"
            
            currencies_input = st.text_input("Supported Currencies", value=default_currencies)
            
            submit = st.form_submit_button("➕ Add Gateway", use_container_width=True)
            
            if submit:
                if gateway_type and public_key and secret_key:
                    currencies_list = [c.strip().upper() for c in currencies_input.split(',') if c.strip()]
                    
                    gateway_data = {
                        "gateway": gateway_type,
                        "public_key": public_key,
                        "secret_key": secret_key,
                        "webhook_secret": webhook_secret,
                        "is_test_mode": is_test_mode,
                        "is_active": is_active,
                        "supported_currencies": currencies_list
                    }
                    
                    if create_payment_gateway_config(gateway_data):
                        st.success(f"{gateway_type.title()} gateway added successfully!")
                        st.rerun()
                    else:
                        st.error("Failed to add payment gateway")
                else:
                    st.error("Please fill in all required fields marked with *")
    
    with tab3:
        st.subheader("Payment Gateway Statistics")
        
        gateway_stats = get_payment_gateway_stats()
        if gateway_stats:
            # Summary metrics
            col1, col2, col3, col4 = st.columns(4)
            
            with col1:
                st.metric("Total Gateways", gateway_stats.get('total_gateway_configs', 0))
            
            with col2:
                st.metric("Active Gateways", gateway_stats.get('active_gateway_configs', 0))
            
            with col3:
                total_payments = sum(stats.get('total_payments', 0) for stats in gateway_stats.get('gateway_stats', {}).values())
                st.metric("Total Payments", total_payments)
            
            with col4:
                total_successful = sum(stats.get('successful_payments', 0) for stats in gateway_stats.get('gateway_stats', {}).values())
                overall_success_rate = (total_successful / total_payments * 100) if total_payments > 0 else 0
                st.metric("Overall Success Rate", f"{overall_success_rate:.1f}%")
            
            # Gateway-specific statistics
            st.markdown("---")
            st.subheader("📊 Gateway Performance")
            
            gateway_stats_data = gateway_stats.get('gateway_stats', {})
            if gateway_stats_data:
                for gateway, stats in gateway_stats_data.items():
                    with st.expander(f"📈 {gateway.title()} Statistics"):
                        col1, col2, col3 = st.columns(3)
                        
                        with col1:
                            st.metric("Total Payments", stats.get('total_payments', 0))
                        
                        with col2:
                            st.metric("Successful Payments", stats.get('successful_payments', 0))
                        
                        with col3:
                            success_rate = stats.get('success_rate', 0)
                            st.metric("Success Rate", f"{success_rate:.1f}%")
            else:
                st.info("No payment statistics available yet")
        else:
            st.info("No gateway statistics available")

def show_wallet_management():
    """Display wallet management interface"""
    st.title("💰 Wallet Management")
    st.markdown("---")
    
    # Create tabs for different wallet management features
    tab1, tab2, tab3, tab4 = st.tabs(["📊 Statistics", "👥 User Wallets", "📋 Transactions", "⚙️ Balance Adjustments"])
    
    with tab1:
        st.subheader("Wallet System Statistics")
        
        wallet_stats = get_wallet_statistics()
        if wallet_stats:
            # Summary metrics
            col1, col2, col3, col4 = st.columns(4)
            
            with col1:
                st.metric("Total Balance", f"₦{wallet_stats.get('total_balance', 0):,.2f}")
            
            with col2:
                st.metric("Users with Wallets", wallet_stats.get('users_with_wallets', 0))
            
            with col3:
                st.metric("Total Transactions", wallet_stats.get('total_transactions', 0))
            
            with col4:
                recent_transactions = wallet_stats.get('recent_activity', {}).get('transactions_last_30_days', 0)
                st.metric("Recent Transactions (30d)", recent_transactions)
            
            # Transaction type breakdown
            st.markdown("---")
            st.subheader("📈 Transaction Types")
            
            transaction_types = wallet_stats.get('transaction_types', {})
            if transaction_types:
                col1, col2, col3, col4 = st.columns(4)
                
                with col1:
                    st.metric("Fund Transactions", transaction_types.get('fund', 0))
                
                with col2:
                    st.metric("Payment Transactions", transaction_types.get('payment', 0))
                
                with col3:
                    st.metric("Withdrawal Transactions", transaction_types.get('withdrawal', 0))
                
                with col4:
                    st.metric("Refund Transactions", transaction_types.get('refund', 0))
            
            # Transaction status breakdown
            st.markdown("---")
            st.subheader("📊 Transaction Status")
            
            transaction_status = wallet_stats.get('transaction_status', {})
            if transaction_status:
                col1, col2, col3 = st.columns(3)
                
                with col1:
                    st.metric("Completed", transaction_status.get('completed', 0))
                
                with col2:
                    st.metric("Pending", transaction_status.get('pending', 0))
                
                with col3:
                    st.metric("Failed", transaction_status.get('failed', 0))
            
            # Recent activity
            st.markdown("---")
            st.subheader("🕒 Recent Activity (Last 30 Days)")
            
            recent_activity = wallet_stats.get('recent_activity', {})
            if recent_activity:
                col1, col2 = st.columns(2)
                
                with col1:
                    st.metric("Transactions", recent_activity.get('transactions_last_30_days', 0))
                
                with col2:
                    balance_added = recent_activity.get('balance_added_last_30_days', 0)
                    st.metric("Balance Added", f"₦{balance_added:,.2f}")
        else:
            st.info("No wallet statistics available")
    
    with tab2:
        st.subheader("User Wallets")
        
        # Search and filter options
        col1, col2 = st.columns([2, 1])
        with col1:
            search_term = st.text_input("Search by user email or name", key="wallet_user_search")
        with col2:
            min_balance = st.number_input("Minimum balance", min_value=0.0, value=0.0, step=100.0, key="min_balance_filter")
        
        # Get users with wallets
        users_with_wallets = get_users_with_wallets()
        
        if users_with_wallets:
            # Filter users based on search and balance
            filtered_users = []
            for user in users_with_wallets:
                if (search_term.lower() in user.get('email', '').lower() or 
                    search_term.lower() in user.get('name', '').lower()) and \
                   user.get('wallet_balance', 0) >= min_balance:
                    filtered_users.append(user)
            
            if filtered_users:
                # Display users in a table
                st.markdown("### User Wallet Balances")
                
                # Create DataFrame for better display
                user_data = []
                for user in filtered_users:
                    user_data.append({
                        "User ID": user.get('user_id'),
                        "Name": user.get('name'),
                        "Email": user.get('email'),
                        "Balance": f"₦{user.get('wallet_balance', 0):,.2f}",
                        "Status": "Active" if user.get('is_active') else "Inactive",
                        "Created": user.get('created_at', '')[:10] if user.get('created_at') else ''
                    })
                
                df = pd.DataFrame(user_data)
                st.dataframe(df, use_container_width=True)
                
                # Summary
                total_balance = sum(user.get('wallet_balance', 0) for user in filtered_users)
                st.markdown(f"**Total Balance: ₦{total_balance:,.2f}**")
            else:
                st.info("No users found matching the criteria")
        else:
            st.info("No users with wallet balances found")
    
    with tab3:
        st.subheader("Wallet Transactions")
        
        # Filter options
        col1, col2, col3 = st.columns(3)
        with col1:
            transaction_type_filter = st.selectbox(
                "Transaction Type",
                ["All", "fund", "payment", "withdrawal", "refund"],
                key="transaction_type_filter"
            )
        with col2:
            status_filter = st.selectbox(
                "Status",
                ["All", "completed", "pending", "failed"],
                key="status_filter"
            )
        with col3:
            limit_filter = st.selectbox(
                "Limit",
                [50, 100, 200, 500],
                key="limit_filter"
            )
        
        # Get transactions
        transaction_type = None if transaction_type_filter == "All" else transaction_type_filter
        status = None if status_filter == "All" else status_filter
        
        transactions = get_all_wallet_transactions(
            limit=limit_filter,
            transaction_type=transaction_type,
            status=status
        )
        
        if transactions:
            # Display transactions in a table
            st.markdown("### Recent Transactions")
            
            transaction_data = []
            for transaction in transactions:
                transaction_data.append({
                    "ID": transaction.get('id'),
                    "User": transaction.get('user_name'),
                    "Type": transaction.get('transaction_type', '').title(),
                    "Amount": f"₦{transaction.get('amount', 0):,.2f}",
                    "Status": transaction.get('status', '').title(),
                    "Gateway": transaction.get('payment_gateway', 'N/A'),
                    "Reference": transaction.get('reference', '')[:15] + "..." if len(transaction.get('reference', '')) > 15 else transaction.get('reference', ''),
                    "Date": transaction.get('created_at', '')[:10] if transaction.get('created_at') else ''
                })
            
            df = pd.DataFrame(transaction_data)
            st.dataframe(df, use_container_width=True)
            
            # Transaction summary
            total_amount = sum(transaction.get('amount', 0) for transaction in transactions)
            st.markdown(f"**Total Amount: ₦{total_amount:,.2f}**")
        else:
            st.info("No transactions found")
    
    with tab4:
        st.subheader("Balance Adjustments")
        st.markdown("⚠️ **Warning**: This action will directly modify user wallet balances. Use with caution.")
        
        # Get all users for selection
        all_users = get_users()
        if all_users:
            # User selection
            user_options = {f"{user.get('first_name', '')} {user.get('last_name', '')} ({user.get('email', '')})": user.get('id') for user in all_users}
            selected_user_display = st.selectbox("Select User", list(user_options.keys()), key="balance_adjustment_user")
            selected_user_id = user_options[selected_user_display]
            
            # Get current user info
            selected_user = next((user for user in all_users if user.get('id') == selected_user_id), None)
            
            if selected_user:
                st.markdown(f"**Current Balance: ₦{selected_user.get('wallet_balance', 0):,.2f}**")
                
                # Adjustment form
                with st.form("balance_adjustment_form"):
                    col1, col2 = st.columns(2)
                    
                    with col1:
                        operation = st.selectbox("Operation", ["add", "subtract"], key="balance_operation")
                        amount = st.number_input("Amount (NGN)", min_value=0.01, value=100.0, step=0.01, key="balance_amount")
                    
                    with col2:
                        reason = st.text_area("Reason for adjustment", key="balance_reason", height=100)
                    
                    submitted = st.form_submit_button("Adjust Balance")
                    
                    if submitted:
                        if not reason.strip():
                            st.error("Please provide a reason for the adjustment")
                        else:
                            result = adjust_user_wallet_balance(selected_user_id, amount, operation, reason)
                            if result:
                                st.success(f"Balance {operation}ed successfully! New balance: ₦{result.get('new_balance', 0):,.2f}")
                                st.rerun()
                            else:
                                st.error("Failed to adjust balance")
        else:
            st.error("No users found")

# Notification Management Functions

def get_all_notifications(skip=0, limit=100):
    try:
        response = requests.get(
            f"{API_BASE_URL}/notifications",
            params={"skip": skip, "limit": limit},
            headers=get_headers()
        )
        return response.json() if response.status_code == 200 else []
    except Exception as e:
        st.error(f"Error fetching notifications: {str(e)}")
        return []

def get_notification_stats():
    try:
        response = requests.get(f"{API_BASE_URL}/notifications/unread-count", headers=get_headers())
        return response.json() if response.status_code == 200 else {"unread_count": 0}
    except Exception as e:
        st.error(f"Error fetching notification stats: {str(e)}")
        return {"unread_count": 0}

def send_test_notification(notification_data):
    try:
        response = requests.post(
            f"{API_BASE_URL}/notifications/test",
            json=notification_data,
            headers=get_headers()
        )
        return response.status_code == 200
    except Exception as e:
        st.error(f"Error sending test notification: {str(e)}")
        return False

def show_notifications_management():
    """Display notification management interface"""
    st.markdown('<h1 class="main-header">🔔 Notification Management</h1>', unsafe_allow_html=True)
    
    tab1, tab2, tab3 = st.tabs(["All Notifications", "Send Test Notification", "Statistics"])
    
    with tab1:
        st.subheader("All Notifications")
        
        # Fetch notifications
        notifications = get_all_notifications(limit=50)
        
        if notifications:
            st.markdown(f"**Showing {len(notifications)} recent notifications**")
            
            # Filter options
            col1, col2, col3 = st.columns(3)
            with col1:
                filter_channel = st.selectbox("Filter by Channel", ["All", "PUSH", "EMAIL", "SMS"])
            with col2:
                filter_status = st.selectbox("Filter by Status", ["All", "PENDING", "SENT", "FAILED", "DELIVERED"])
            with col3:
                filter_type = st.selectbox("Filter by Type", ["All", "APPOINTMENT_CONFIRMATION", "APPOINTMENT_REMINDER", "PAYMENT_SUCCESS", "PAYMENT_FAILED"])
            
            # Apply filters
            filtered_notifications = notifications
            if filter_channel != "All":
                filtered_notifications = [n for n in filtered_notifications if n.get('channel') == filter_channel]
            if filter_status != "All":
                filtered_notifications = [n for n in filtered_notifications if n.get('status') == filter_status]
            if filter_type != "All":
                filtered_notifications = [n for n in filtered_notifications if n.get('notification_type') == filter_type]
            
            # Display notifications
            for notification in filtered_notifications:
                status_emoji = {
                    "PENDING": "⏳",
                    "SENT": "✅",
                    "FAILED": "❌",
                    "DELIVERED": "📬"
                }.get(notification.get('status', 'PENDING'), "❓")
                
                channel_emoji = {
                    "PUSH": "📱",
                    "EMAIL": "📧",
                    "SMS": "💬"
                }.get(notification.get('channel', 'PUSH'), "📢")
                
                with st.expander(f"{status_emoji} {channel_emoji} {notification.get('title', 'No Title')} - {notification.get('created_at', 'N/A')}"):
                    col1, col2 = st.columns([2, 1])
                    
                    with col1:
                        st.markdown(f"**ID:** {notification.get('id')}")
                        st.markdown(f"**User ID:** {notification.get('user_id')}")
                        st.markdown(f"**Type:** {notification.get('notification_type')}")
                        st.markdown(f"**Title:** {notification.get('title')}")
                        st.markdown(f"**Message:**")
                        st.write(notification.get('message', 'No message'))
                        
                        if notification.get('data'):
                            st.markdown("**Additional Data:**")
                            st.json(notification.get('data'))
                    
                    with col2:
                        st.markdown(f"**Channel:** {notification.get('channel')}")
                        st.markdown(f"**Status:** {notification.get('status')}")
                        st.markdown(f"**Retry Count:** {notification.get('retry_count', 0)}")
                        
                        if notification.get('scheduled_at'):
                            st.markdown(f"**Scheduled:** {notification.get('scheduled_at')}")
                        if notification.get('sent_at'):
                            st.markdown(f"**Sent:** {notification.get('sent_at')}")
                        if notification.get('delivered_at'):
                            st.markdown(f"**Delivered:** {notification.get('delivered_at')}")
                        if notification.get('failed_reason'):
                            st.error(f"**Failed Reason:** {notification.get('failed_reason')}")
                        if notification.get('read_at'):
                            st.markdown(f"**Read:** {notification.get('read_at')}")
        else:
            st.info("No notifications found")
    
    with tab2:
        st.subheader("Send Test Notification")
        
        with st.form("test_notification_form"):
            user_id = st.number_input("User ID", min_value=1, value=1)
            channel = st.selectbox("Channel", ["PUSH", "EMAIL", "SMS"])
            notification_type = st.selectbox("Type", [
                "APPOINTMENT_CONFIRMATION",
                "APPOINTMENT_REMINDER",
                "PAYMENT_SUCCESS",
                "PAYMENT_FAILED",
                "GENERAL"
            ])
            title = st.text_input("Title", value="Test Notification")
            message = st.text_area("Message", value="This is a test notification from the admin dashboard.")
            
            submitted = st.form_submit_button("Send Test Notification")
            
            if submitted:
                notification_data = {
                    "user_id": user_id,
                    "channel": channel,
                    "notification_type": notification_type,
                    "title": title,
                    "message": message
                }
                
                if send_test_notification(notification_data):
                    st.success("✅ Test notification sent successfully!")
                else:
                    st.error("❌ Failed to send test notification")
    
    with tab3:
        st.subheader("Notification Statistics")
        
        # Get stats
        stats = get_notification_stats()
        
        # Display stats
        col1, col2, col3 = st.columns(3)
        
        with col1:
            st.metric("Unread Notifications", stats.get('unread_count', 0))
        
        with col2:
            # Count by status
            notifications = get_all_notifications(limit=1000)
            sent_count = len([n for n in notifications if n.get('status') == 'SENT'])
            st.metric("Sent Notifications", sent_count)
        
        with col3:
            failed_count = len([n for n in notifications if n.get('status') == 'FAILED'])
            st.metric("Failed Notifications", failed_count)
        
        # Channel breakdown
        st.markdown("### Notifications by Channel")
        channel_counts = {}
        for n in notifications:
            channel = n.get('channel', 'UNKNOWN')
            channel_counts[channel] = channel_counts.get(channel, 0) + 1
        
        if channel_counts:
            st.bar_chart(channel_counts)
        
        # Type breakdown
        st.markdown("### Notifications by Type")
        type_counts = {}
        for n in notifications:
            ntype = n.get('notification_type', 'UNKNOWN')
            type_counts[ntype] = type_counts.get(ntype, 0) + 1
        
        if type_counts:
            st.bar_chart(type_counts)

def show_reviews_management():
    """Display review management interface"""
    st.markdown('<h1 class="main-header">📝 Review Management</h1>', unsafe_allow_html=True)
    
    tab1, tab2, tab3 = st.tabs(["Flagged Reviews", "All Reviews", "Statistics"])
    
    with tab1:
        st.subheader("Flagged Reviews Requiring Moderation")
        
        # Fetch flagged reviews
        try:
            response = requests.get(
                f"{API_BASE_URL}/reviews",
                params={"include_hidden": True},
                headers=get_headers()
            )
            
            if response.status_code == 200:
                data = response.json()
                all_reviews = data.get('reviews', [])
                flagged_reviews = [r for r in all_reviews if r.get('is_flagged', False)]
                
                if flagged_reviews:
                    st.markdown(f"**{len(flagged_reviews)} flagged reviews**")
                    
                    for review in flagged_reviews:
                        with st.expander(f"Review #{review.get('id')} - {review.get('flag_count', 0)} flags"):
                            col1, col2 = st.columns([2, 1])
                            
                            with col1:
                                # Review details
                                st.markdown(f"**Hospital ID:** {review.get('hospital_id')}")
                                st.markdown(f"**Rating:** {'⭐' * review.get('rating', 0)}")
                                st.markdown(f"**Comment:**")
                                st.write(review.get('comment', 'No comment'))
                                st.markdown(f"**Posted:** {review.get('created_at', 'N/A')}")
                                st.markdown(f"**Flag Count:** {review.get('flag_count', 0)}")
                                st.markdown(f"**Hidden:** {'Yes' if review.get('is_hidden') else 'No'}")
                                
                                if review.get('hospital_response'):
                                    st.markdown("**Hospital Response:**")
                                    st.info(review.get('hospital_response'))
                            
                            with col2:
                                st.markdown("**Moderation Actions**")
                                
                                # Action buttons
                                if st.button("✅ Approve (Show)", key=f"approve_{review.get('id')}"):
                                    try:
                                        mod_response = requests.put(
                                            f"{API_BASE_URL}/reviews/{review.get('id')}/moderate",
                                            json={"action": "show", "reason": "Approved by admin"},
                                            headers=get_headers()
                                        )
                                        if mod_response.status_code == 200:
                                            st.success("Review approved!")
                                            st.rerun()
                                        else:
                                            st.error(f"Failed to approve: {mod_response.status_code}")
                                    except Exception as e:
                                        st.error(f"Error: {str(e)}")
                                
                                if st.button("🚫 Hide", key=f"hide_{review.get('id')}"):
                                    try:
                                        mod_response = requests.put(
                                            f"{API_BASE_URL}/reviews/{review.get('id')}/moderate",
                                            json={"action": "hide", "reason": "Hidden by admin"},
                                            headers=get_headers()
                                        )
                                        if mod_response.status_code == 200:
                                            st.success("Review hidden!")
                                            st.rerun()
                                        else:
                                            st.error(f"Failed to hide: {mod_response.status_code}")
                                    except Exception as e:
                                        st.error(f"Error: {str(e)}")
                                
                                if st.button("🗑️ Delete", key=f"delete_{review.get('id')}"):
                                    try:
                                        mod_response = requests.put(
                                            f"{API_BASE_URL}/reviews/{review.get('id')}/moderate",
                                            json={"action": "delete", "reason": "Deleted by admin"},
                                            headers=get_headers()
                                        )
                                        if mod_response.status_code == 200:
                                            st.success("Review deleted!")
                                            st.rerun()
                                        else:
                                            st.error(f"Failed to delete: {mod_response.status_code}")
                                    except Exception as e:
                                        st.error(f"Error: {str(e)}")
                else:
                    st.success("✅ No flagged reviews requiring moderation")
            else:
                st.error(f"Failed to fetch reviews: {response.status_code}")
        except Exception as e:
            st.error(f"Error fetching flagged reviews: {str(e)}")
    
    with tab2:
        st.subheader("All Reviews")
        
        # Filters
        col1, col2, col3 = st.columns(3)
        with col1:
            filter_hospital = st.number_input("Filter by Hospital ID", min_value=0, value=0, step=1)
        with col2:
            filter_rating = st.selectbox("Filter by Rating", ["All", "1", "2", "3", "4", "5"])
        with col3:
            show_hidden = st.checkbox("Show Hidden Reviews", value=False)
        
        # Fetch reviews
        try:
            params = {"include_hidden": show_hidden}
            if filter_hospital > 0:
                params["hospital_id"] = filter_hospital
            if filter_rating != "All":
                params["rating"] = int(filter_rating)
            
            response = requests.get(
                f"{API_BASE_URL}/reviews",
                params=params,
                headers=get_headers()
            )
            
            if response.status_code == 200:
                data = response.json()
                reviews = data.get('reviews', [])
                
                if reviews:
                    # Display reviews in a table
                    review_data = []
                    for review in reviews:
                        review_data.append({
                            "ID": review.get('id'),
                            "Hospital ID": review.get('hospital_id'),
                            "Rating": '⭐' * review.get('rating', 0),
                            "Comment": review.get('comment', '')[:50] + '...' if len(review.get('comment', '')) > 50 else review.get('comment', ''),
                            "Flagged": "Yes" if review.get('is_flagged') else "No",
                            "Hidden": "Yes" if review.get('is_hidden') else "No",
                            "Flag Count": review.get('flag_count', 0),
                            "Created": review.get('created_at', 'N/A')[:10]
                        })
                    
                    df = pd.DataFrame(review_data)
                    st.dataframe(df, use_container_width=True)
                    
                    st.markdown(f"**Total Reviews: {len(reviews)}**")
                else:
                    st.info("No reviews found")
            else:
                st.error(f"Failed to fetch reviews: {response.status_code}")
        except Exception as e:
            st.error(f"Error fetching reviews: {str(e)}")
    
    with tab3:
        st.subheader("Review Statistics")
        
        # Fetch all reviews for statistics
        try:
            response = requests.get(
                f"{API_BASE_URL}/reviews",
                params={"include_hidden": True},
                headers=get_headers()
            )
            
            if response.status_code == 200:
                data = response.json()
                reviews = data.get('reviews', [])
                
                if reviews:
                    # Calculate statistics
                    total_reviews = len(reviews)
                    flagged_count = sum(1 for r in reviews if r.get('is_flagged'))
                    hidden_count = sum(1 for r in reviews if r.get('is_hidden'))
                    avg_rating = data.get('average_rating', 0)
                    rating_dist = data.get('rating_distribution', {})
                    
                    # Display metrics
                    col1, col2, col3, col4 = st.columns(4)
                    with col1:
                        st.metric("Total Reviews", total_reviews)
                    with col2:
                        st.metric("Flagged Reviews", flagged_count)
                    with col3:
                        st.metric("Hidden Reviews", hidden_count)
                    with col4:
                        st.metric("Average Rating", f"{avg_rating:.2f}")
                    
                    # Rating distribution chart
                    if rating_dist:
                        st.subheader("Rating Distribution")
                        rating_df = pd.DataFrame([
                            {"Rating": f"{k} ⭐", "Count": v}
                            for k, v in sorted(rating_dist.items(), reverse=True)
                        ])
                        fig = px.bar(rating_df, x="Rating", y="Count", title="Reviews by Rating")
                        st.plotly_chart(fig, use_container_width=True)
                    
                    # Reviews over time
                    st.subheader("Reviews Over Time")
                    reviews_by_date = {}
                    for review in reviews:
                        date = review.get('created_at', '')[:10]
                        reviews_by_date[date] = reviews_by_date.get(date, 0) + 1
                    
                    if reviews_by_date:
                        time_df = pd.DataFrame([
                            {"Date": k, "Count": v}
                            for k, v in sorted(reviews_by_date.items())
                        ])
                        fig = px.line(time_df, x="Date", y="Count", title="Reviews Over Time")
                        st.plotly_chart(fig, use_container_width=True)
                else:
                    st.info("No reviews available for statistics")
            else:
                st.error(f"Failed to fetch reviews: {response.status_code}")
        except Exception as e:
            st.error(f"Error fetching review statistics: {str(e)}")

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
            options=["Dashboard", "Users", "Medical Records", "Hospitals", "Doctors", "Services", "Appointments", "Payments", "Payment Gateways", "Wallet Management", "Reviews", "Notifications", "Logout"],
            icons=["speedometer2", "people", "clipboard-check", "hospital", "person-badge", "gear", "calendar-check", "credit-card", "credit-card-2", "wallet", "star", "bell", "box-arrow-right"],
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
    elif selected == "Services":
        show_services_management()
    elif selected == "Appointments":
        show_appointments_management()
    elif selected == "Payments":
        show_payments_management()
    elif selected == "Payment Gateways":
        show_payment_gateways_management()
    elif selected == "Wallet Management":
        show_wallet_management()
    elif selected == "Reviews":
        show_reviews_management()
    elif selected == "Notifications":
        show_notifications_management()


if __name__ == "__main__":
    main()
