import axios from 'axios';

async function fetchPlans() {
  try {
    const res = await axios.get('https://sandbox.vtpass.com/api/service-variations?serviceID=mtn-data', {
      headers: {
        'api-key': '91c3d1ed178351b6a782a63db98cb151',
        'public-key': 'PK_58a8f1585bb9a7c37613768b7ca7427ef560111f'
      }
    });
    console.log(res.data.content.varations.slice(0, 10));
  } catch(e) {
    console.error(e.response ? e.response.data : e.message);
  }
}

fetchPlans();
