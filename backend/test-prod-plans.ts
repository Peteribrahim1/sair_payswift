import axios from 'axios';

async function run() {
  try {
    // Note: hitting the actual endpoint the app hits
    // The flutter app hits: ${ApiConfig.baseUrl}/services/sme-data-plans/MTN
    // Since it requires authentication, we might get 401. Let's see if we can get a token or just test the route exists.
    const res = await axios.get('https://sair-payswift.onrender.com/api/services/sme-data-plans/MTN');
    console.log('Production SME Plans:', res.data);
  } catch (e: any) {
    console.error('Error fetching prod sme plans:', e.response?.status, e.response?.data || e.message);
  }
}

run();
